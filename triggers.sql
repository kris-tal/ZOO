------ sprawdzam czy pesel jest poprawny
CREATE OR REPLACE FUNCTION dobry_pesel() RETURNS TRIGGER AS $$
DECLARE
  tab NUMERIC[] := ARRAY[1, 3, 7, 9, 1, 3, 7, 9, 1, 3];
  suma NUMERIC := 0;
  i NUMERIC;
BEGIN
    IF NEW.pesele IS NULL THEN
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
CREATE FUNCTION check_godziny_otwarcia() RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.id_popisu IS NULL THEN RETURN NEW; END IF;        --dla srzatania i karmienia nie sprawdzamy
    IF NEW.godzina_od < (SELECT otwarcie FROM godziny_otwarcia LIMIT 1) THEN
        RAISE EXCEPTION 'Godzina rozpoczęcia musi być po godzinie otwarcia';
    END IF;

    IF NEW.godzina_do > (SELECT zamkniecie FROM godziny_otwarcia LIMIT 1) THEN
        RAISE EXCEPTION 'Godzina zakończenia musi być przed godziną zamknięcia';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER akt_popisow
    BEFORE INSERT OR UPDATE ON plan_tygodnia
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
        FROM plan_tygodnia
        WHERE id_popisu IS NOT NULL
        AND ((godzina_od < NEW.otwarcie) OR (godzina_do > NEW.zamkniecie))
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
------ pilnuje czy jest tylko jedna krotka w relacji godziny_otwarcia
CREATE OR REPLACE FUNCTION jeden() RETURNS TRIGGER
AS $$
DECLARE
    licznik INTEGER;
BEGIN
    SELECT COUNT(*) INTO licznik FROM godziny_otwarcia;

    IF TG_OP = 'INSERT' AND licznik = 1 THEN
        RAISE EXCEPTION 'Nie można dodać więcej niż jednych godzin otwarcia. Możesz je edytować';
    ELSEIF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Nie można usunąć jedynego wiersza w tabeli';
    END IF;

    IF TG_OP = 'INSERT' THEN RETURN NEW;
    ELSE RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pojedynczy_wiersz
    BEFORE INSERT OR DELETE ON godziny_otwarcia
    FOR EACH ROW EXECUTE FUNCTION jeden();

-------------------------------------------------------------------------------------
=================================== HISTORIC TRIGGERS =========================================

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