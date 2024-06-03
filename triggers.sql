------ sprawdzam czy pesel jest poprawny
CREATE OR REPLACE FUNCTION dobry_pesel() RETURNS TRIGGER AS $$
DECLARE
  tab NUMERIC[] := ARRAY[1, 3, 7, 9, 1, 3, 7, 9, 1, 3];
  suma NUMERIC := 0;
  i NUMERIC;
BEGIN
    IF NEW.pesel IS NULL THEN
        RETURN NEW;
    END IF;
    
  IF LENGTH(NEW.pesel) != 11 THEN
    RAISE EXCEPTION 'Niepoprawny PESEL';
  END IF;

  FOR i IN 1..10 LOOP
    suma := suma + tab[i] * CAST(SUBSTRING(NEW.pesel, i, 1) AS NUMERIC);
  END LOOP;

  suma := 10 - (suma % 10);
  IF suma = 10 THEN
    suma := 0;
  END IF;

  IF suma != CAST(SUBSTRING(NEW.pesel, 11, 1) AS NUMERIC) THEN
    RAISE EXCEPTION 'Niepoprawny PESEL';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER dobry_pesel
BEFORE INSERT OR UPDATE ON pracownicy
FOR EACH ROW EXECUTE PROCEDURE dobry_pesel();
-------------------------------------------------------------------------------------

------ updatuje licznosc gatunku
CREATE FUNCTION update_licznosc_gatunku()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE gatunki
    SET licznosc = (
        SELECT COUNT(*)
        FROM zwierzeta
        WHERE zwierzeta.gatunek = NEW.gatunek
    )
    WHERE id = NEW.gatunek;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER change_zwierzeta
    AFTER INSERT OR UPDATE OR DELETE ON zwierzeta
    FOR EACH ROW EXECUTE FUNCTION update_licznosc_gatunku();
-------------------------------------------------------------------------------------
------ sprawdzam czy popis nie jest poza czasem otwarcia zoo
CREATE OR REPLACE FUNCTION check_godziny_otwarcia() RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.id_popisu IS NULL THEN RETURN NEW; END IF;        --dla srzatania i karmienia nie sprawdzamy
    IF NEW.godzina_od < (SELECT otwarcie FROM godziny_otwarcia WHERE extract(isodow from NEW.data) = dzien_tygodnia LIMIT 1) THEN
        RAISE EXCEPTION 'Godzina rozpoczęcia musi być po godzinie otwarcia';
    END IF;

    IF NEW.godzina_do > (SELECT zamkniecie FROM godziny_otwarcia WHERE extract(isodow from NEW.data) = dzien_tygodnia LIMIT 1) THEN
        RAISE EXCEPTION 'Godzina zakończenia musi być przed godziną zamknięcia';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER akt_popisow
    BEFORE INSERT OR UPDATE ON plan_dnia
    FOR EACH ROW EXECUTE FUNCTION check_godziny_otwarcia();
-------------------------------------------------------------------------------------

-- musze zrobic to w druga strone - jak updatuje godz otwarcia to musze sprawdzic wszystko w planie dnia czy pasuje
-- i albo nie pozwolic zmienic albo usunac
------ sprawdzam czy nowe godziny otwarcia nie koliduja z jakimis popisami
CREATE FUNCTION check_godzina_popisow() RETURNS TRIGGER
AS $$
BEGIN
    IF EXISTS (
        SELECT true
        FROM plan_dnia
        WHERE id_popisu IS NOT NULL
        AND ((godzina_od < NEW.otwarcie) OR (godzina_do > NEW.zamkniecie)) AND NEW.dzien_tygodnia = extract(isodow from plan_dnia.data)
    ) THEN
        RAISE EXCEPTION 'Nowa godzinaina rozpoczęcia koliduje z istniejącymi popisami';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER aktualizacja_godziny_otwarcia
    BEFORE INSERT OR UPDATE ON godziny_otwarcia
    FOR EACH ROW EXECUTE FUNCTION check_godzina_popisow();
-------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION check_plan_dnia()
RETURNS TRIGGER AS $$
DECLARE
    dodawany_id INTEGER;
BEGIN
    IF NEW.id_sprzatacza IS NOT NULL THEN dodawany_id = NEW.id_sprzatacza;
    ELSIF NEW.id_karmienia IS NOT NULL THEN dodawany_id = NEW.id_karmienia;
    ELSIF NEW.id_popisu IS NOT NULL THEN dodawany_id = NEW.id_popisu;
    END IF;

    -- nieobecnosci
    IF EXISTS(
       SELECT true FROM nieobecnosci_pracownikow
       WHERE NEW.data >= data_od AND NEW.data <= data_do AND id_pracownika = dodawany_id
    ) THEN
       RETURN NULL;
    END IF;

    -- godziny pracy
    IF EXISTS(
        SELECT true FROM pracownicy_godziny_pracy
        WHERE id_pracownika = dodawany_id AND (NEW.godzina_od < godzina_od OR NEW.godzina_do > godzina_do)
    ) THEN
        RETURN NULL;
    END IF;

    -- pracownik dwie rzeczy naraz
    IF EXISTS(
        SELECT true FROM plan_dnia
        WHERE (id_popisu = dodawany_id OR id_karmienia = dodawany_id OR id_sprzatacza = dodawany_id)
        AND data = NEW.data
        AND (godzina_od <= NEW.godzina_od AND NEW.godzina_od < godzina_do
                 OR godzina_od < NEW.godzina_do AND NEW.godzina_do <= godzina_do)
    ) THEN
        RETURN NULL;
    END IF;

    RETURN NEW;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_plan_dnia
    BEFORE INSERT OR UPDATE ON plan_dnia
    FOR EACH ROW EXECUTE FUNCTION check_plan_dnia();


CREATE OR REPLACE FUNCTION check_popisy()
RETURNS TRIGGER AS $check_popisy$
DECLARE
    popis RECORD;
    dostepne_zwierzeta INTEGER;
    niedostepne_zwierzeta INTEGER;
BEGIN
    IF NEW.id_popisu IS NULL THEN RETURN NEW; END IF;

    SELECT * INTO popis FROM popisy
    WHERE id = NEW.id_popisu;

    SELECT COUNT(*) INTO dostepne_zwierzeta FROM gatunki JOIN zwierzeta ON gatunek = gatunki.id
    WHERE poziom_umiejetnosci >= popis.min_poziom_umiejetnosci AND gatunek = popis.gatunek;

    SELECT SUM(min_ilosc) INTO niedostepne_zwierzeta FROM plan_dnia JOIN popisy ON id_popisu = popisy.id
    WHERE id_popisu = NEW.id_popisu
    AND (godzina_od < NEW.godzina_do AND NEW.godzina_do <= godzina_do
        OR godzina_od <= NEW.godzina_od AND NEW.godzina_od < godzina_do);

    IF dostepne_zwierzeta - niedostepne_zwierzeta < popis.min_ilosc THEN
        RETURN NULL;
    END IF;

    RETURN NEW;
END;
$check_popisy$ LANGUAGE plpgsql;

CREATE TRIGGER check_popisy
    BEFORE INSERT OR UPDATE ON plan_dnia
    FOR EACH ROW EXECUTE FUNCTION check_popisy();
-------------------------------------------------------------------------------------
--=================================== HISTORIC TRIGGERS =========================================

CREATE OR REPLACE FUNCTION dodaj_do_historii_zwierzat() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historia_zwierzat (id_zwierzecia, data_usuniecia)
    VALUES (OLD.id, CURRENT_DATE);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historia_zwierzat_trigger
AFTER DELETE ON zwierzeta
FOR EACH ROW
EXECUTE PROCEDURE dodaj_do_historii_zwierzat();

CREATE OR REPLACE FUNCTION dodaj_do_historii_gatunkow() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historia_gatunkow (id_gatunku, data_usuniecia)
    VALUES (OLD.id, CURRENT_DATE);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historia_gatunkow_trigger
AFTER DELETE ON gatunki
FOR EACH ROW
EXECUTE PROCEDURE dodaj_do_historii_gatunkow();

CREATE OR REPLACE FUNCTION dodaj_do_historii_wybiegow() RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO historia_wybiegow (id_wybiegu, data_usuniecia)
    VALUES (OLD.id, CURRENT_DATE);
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER historia_wybiegow_trigger
AFTER DELETE ON wybiegi
FOR EACH ROW
EXECUTE PROCEDURE dodaj_do_historii_wybiegow();
