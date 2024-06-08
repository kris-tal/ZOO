--========================================= DROP IF EXISTS =========================================--

DROP TABLE IF EXISTS godziny_otwarcia CASCADE;
DROP TABLE IF EXISTS historia_godziny_otwarcia CASCADE;
DROP TABLE IF EXISTS pracownicy CASCADE;
DROP TABLE IF EXISTS pracownicy_godziny_pracy CASCADE;
DROP TABLE IF EXISTS stanowiska CASCADE;
DROP TABLE IF EXISTS strefy CASCADE;
DROP TABLE IF EXISTS wybiegi CASCADE;
DROP TABLE IF EXISTS gatunki CASCADE;
DROP TABLE IF EXISTS zwierzeta CASCADE;
DROP TABLE IF EXISTS pracownicy_stanowiska CASCADE;
DROP TABLE IF EXISTS trenerzy_gatunki CASCADE;
DROP TABLE IF EXISTS opiekunowie_gatunki CASCADE;
DROP TABLE IF EXISTS sprzatacze_wybiegi CASCADE;
DROP TABLE IF EXISTS niedyspozycja_zwierzat CASCADE;
DROP TABLE IF EXISTS nieobecnosci_pracownikow CASCADE;
DROP TABLE IF EXISTS popisy CASCADE;
DROP TABLE IF EXISTS plan_dnia CASCADE;
DROP TABLE IF EXISTS historia_plan_dnia CASCADE;
DROP VIEW IF EXISTS plan_24h CASCADE;
DROP VIEW IF EXISTS plan_godziny_otwarcia CASCADE;

--========================================= ZWYKLE FUNKCJE =========================================--


--========================================= RELACJE =========================================--

CREATE TABLE godziny_otwarcia (
    dzien_tygodnia INTEGER PRIMARY KEY CHECK(dzien_tygodnia >= 1 AND dzien_tygodnia <= 7),
    otwarcie TIME NOT NULL,
    zamkniecie TIME CHECK(zamkniecie > otwarcie) NOT NULL
);

CREATE TABLE pracownicy (
    id SERIAL PRIMARY KEY,
    imie VARCHAR(40) NOT NULL,
    nazwisko VARCHAR(40) NOT NULL,
    pesel CHAR(11),
    haslo VARCHAR(200),
    UNIQUE(imie, nazwisko, pesel)
);

CREATE TABLE pracownicy_godziny_pracy (
    id_pracownika INTEGER NOT NULL,
    dzien_tygodnia INTEGER CHECK(dzien_tygodnia >= 1 AND dzien_tygodnia <= 7) NOT NULL,
    godzina_od TIME DEFAULT '8:00'::time NOT NULL ,
    godzina_do TIME DEFAULT '15:00'::time NOT NULL,
    CHECK(godzina_od < godzina_do),
    PRIMARY KEY(id_pracownika, dzien_tygodnia),
    FOREIGN KEY(id_pracownika) REFERENCES pracownicy (id)
);

CREATE TABLE stanowiska (
    id SERIAL PRIMARY KEY,
    nazwa CHAR(40) NOT NULL UNIQUE
);

CREATE TABLE strefy (
    id SERIAL PRIMARY KEY,
    nazwa VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE wybiegi (
    id SERIAL PRIMARY KEY,
    strefa INTEGER REFERENCES strefy(id) NOT NULL
);

CREATE TABLE gatunki (
    id SERIAL PRIMARY KEY,
    nazwa VARCHAR(100) NOT NULL UNIQUE,
    id_wybiegu INTEGER REFERENCES wybiegi(id) NOT NULL
);

CREATE TABLE zwierzeta (
    id SERIAL PRIMARY KEY,
    gatunek INTEGER REFERENCES gatunki(id) NOT NULL,
    imie VARCHAR(40),
    poziom_umiejetnosci INTEGER CHECK(poziom_umiejetnosci >= 0 AND poziom_umiejetnosci <= 10) NOT NULL,
    data_dodania DATE NOT NULL  --dodac do insertow
);

CREATE TABLE pracownicy_stanowiska (
    id_pracownika INTEGER REFERENCES pracownicy(id),
    id_stanowiska INTEGER REFERENCES stanowiska(id),
    data_dodania DATE NOT NULL,
    PRIMARY KEY(id_pracownika, id_stanowiska)
);


CREATE TABLE trenerzy_gatunki ( --kazdy trener musi miec przypisany gatunek
    id_pracownika INTEGER REFERENCES pracownicy(id),
    id_gatunku INTEGER REFERENCES gatunki(id),
    PRIMARY KEY(id_pracownika, id_gatunku)
);

CREATE TABLE opiekunowie_gatunki (
    id_pracownika INTEGER REFERENCES pracownicy(id),
    id_gatunku INTEGER REFERENCES gatunki(id),
    PRIMARY KEY(id_pracownika, id_gatunku)
);

CREATE TABLE sprzatacze_wybiegi (
    id_pracownika INTEGER REFERENCES pracownicy(id),
    id_wybiegu INTEGER REFERENCES wybiegi(id),
    PRIMARY KEY(id_pracownika, id_wybiegu)
);

CREATE TABLE nieobecnosci_pracownikow (
    id SERIAL PRIMARY KEY,
    id_pracownika INTEGER REFERENCES pracownicy(id) NOT NULL,
    data_od DATE NOT NULL,
    data_do DATE NOT NULL CHECK (data_do >= data_od ),
    powod VARCHAR(200)
);

CREATE TABLE niedyspozycja_zwierzat (
    id SERIAL PRIMARY KEY,
    id_zwierzecia INTEGER REFERENCES zwierzeta(id) NOT NULL,
    data_od DATE NOT NULL,
    data_do DATE NOT NULL CHECK (data_do >= data_od ),
    powod VARCHAR(200)
);

CREATE TABLE popisy (
    id SERIAL PRIMARY KEY,
    nazwa VARCHAR(100) NOT NULL,
    trener INTEGER REFERENCES pracownicy(id) NOT NULL,
    gatunek INTEGER REFERENCES gatunki(id) NOT NULL,
    min_ilosc INTEGER CHECK(min_ilosc > 0),
    min_poziom_umiejetnosci INTEGER CHECK(min_ilosc >= 0 AND min_poziom_umiejetnosci <= 10)
);

CREATE TABLE plan_dnia (
    id SERIAL PRIMARY KEY,
    data DATE NOT NULL,
    godzina_od TIME NOT NULL,
    godzina_do TIME NOT NULL,
    id_sprzatacza INTEGER REFERENCES wybiegi(id),
    id_karmienia INTEGER REFERENCES gatunki(id),
    id_popisu INTEGER REFERENCES popisy(id),
    CHECK(CASE WHEN id_sprzatacza IS NULL THEN 0 ELSE 1 END + CASE WHEN id_karmienia IS NULL THEN 0 ELSE 1 END + CASE WHEN id_popisu IS NULL THEN 0 ELSE 1 END = 1)
);

CREATE TABLE historia_plan_dnia ( -- tu nie robimy checkow bo nie da sie insertowac
    id INTEGER PRIMARY KEY,
    data DATE NOT NULL,
    godzina_od TIME NOT NULL,
    godzina_do TIME NOT NULL,
    id_sprzatacza INTEGER REFERENCES wybiegi(id),
    id_karmienia INTEGER REFERENCES gatunki(id),
    id_popisu INTEGER REFERENCES popisy(id)
);
-- tu nic nie mona dodawac

CREATE VIEW plan_24h AS
SELECT
data, pt.godzina_od, pt.godzina_do,
CASE WHEN id_sprzatacza IS NOT NULL THEN 'sprzatanie'
WHEN id_karmienia IS NOT NULL THEN 'karmienie'
ELSE 'popis' END AS rodzaj,
w.id AS wybieg, s.nazwa AS strefa, p.nazwa AS id_popisu, pr.id AS id_trener, pr.imie, pr.nazwisko, gat.nazwa AS gatunek, min_ilosc, min_poziom_umiejetnosci, g.nazwa, g.id_wybiegu

FROM plan_dnia pt
LEFT OUTER JOIN wybiegi w ON pt.id_sprzatacza = w.id
LEFT OUTER JOIN popisy p ON pt.id_popisu = p.id
LEFT OUTER JOIN gatunki g ON pt.id_karmienia = g.id
LEFT OUTER JOIN strefy s ON w.strefa = s.id
LEFT OUTER JOIN pracownicy pr ON p.trener = pr.id
LEFT OUTER JOIN gatunki gat ON p.gatunek = gat.id

ORDER BY data, godzina_od;

-- otwarcie/zamkniecie w trsakcie kar/sprz
CREATE VIEW plan_godziny_otwarcia AS
SELECT * FROM plan_24h
WHERE godzina_od > (SELECT otwarcie FROM godziny_otwarcia WHERE dzien_tygodnia = extract(isodow from data))
AND godzina_do < (SELECT zamkniecie FROM godziny_otwarcia WHERE dzien_tygodnia = extract(isodow from data))
ORDER BY data, godzina_od;

--=================== histora ====================
CREATE TABLE historia_wybiegow AS SELECT *, NULL::date as data_usuniecia FROM wybiegi;
ALTER TABLE historia_wybiegow ADD PRIMARY KEY (id, data_usuniecia);
ALTER TABLE historia_wybiegow ADD FOREIGN KEY (strefa) REFERENCES strefy(id);

CREATE TABLE historia_zwierzat AS SELECT *, NULL::date as data_usuniecia FROM zwierzeta;
ALTER TABLE historia_zwierzat ADD PRIMARY KEY (id, data_usuniecia);
ALTER TABLE historia_zwierzat ADD FOREIGN KEY (gatunek) REFERENCES gatunki(id);

CREATE TABLE historia_pracownikow AS SELECT *, NULL::date as data_usuniecia FROM pracownicy;
ALTER TABLE historia_pracownikow ADD PRIMARY KEY (id, data_usuniecia);

CREATE TABLE historia_godzin_otwarcia AS SELECT *, NULL::date as data_usuniecia FROM godziny_otwarcia;
ALTER TABLE historia_wybiegow ADD PRIMARY KEY (id, data_usuniecia);

--========================================= TRIGGERY =========================================--

CREATE OR REPLACE FUNCTION moj_hash(str text)
RETURNS integer AS $$
DECLARE
    hash_value integer := 0;
    prime integer := 31;
    mod integer := 1000000007;
    c char;
BEGIN
    FOR i in 1..length(str) LOOP
        c := substr(str, i, 1);
        hash_value := (hash_value * prime + ascii(c)) % mod;
    END LOOP;
    RETURN hash_value;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER hash_password
BEFORE INSERT OR UPDATE ON pracownicy
FOR EACH ROW
EXECUTE FUNCTION moj_hash();


--============================================== INDEKSY =============================================--
-- CREATE INDEX idx_zwierzeta_gatunek ON zwierzeta(gatunek);

--========================================= TRIGGERY =========================================--
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
CREATE OR REPLACE FUNCTION historia_planu()
RETURNS TRIGGER AS $historia_planu$
DECLARE
    plan RECORD;
BEGIN
    FOR plan IN SELECT * FROM plan_dnia LOOP
        IF plan.data < CURRENT_DATE THEN
            INSERT INTO historia_plan_dnia VALUES
            (plan.id, plan.data, plan.godzina_od, plan.godzina_do, plan.id_sprzatacza, plan.id_karmienia, plan.id_popisu);
            DELETE FROM plan_dnia WHERE id = plan.id;
        END IF;
    END LOOP;
    RETURN NEW;
END;
$historia_planu$ LANGUAGE plpgsql;

CREATE TRIGGER historia_planu BEFORE INSERT OR UPDATE ON plan_dnia
FOR EACH ROW EXECUTE FUNCTION historia_planu();


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
        IF NEW.id_popisu IS NOT NULL THEN
            RAISE NOTICE 'Trener prowadzacy popis jest nieobecny';
            RETURN NULL;
        END IF;
        RAISE NOTICE 'Pracownik nieobecny'; --zastepstwa
        RETURN NULL;
    END IF;

    -- godziny pracy
    IF EXISTS(
        SELECT true FROM pracownicy_godziny_pracy
        WHERE id_pracownika = dodawany_id AND (NEW.godzina_od < godzina_od OR NEW.godzina_do > godzina_do)
    ) THEN
        RAISE NOTICE 'Wydarzenie poza godzinami pracy pracownika';
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
        RAISE NOTICE 'Pracownik jest wtedy zajęty';
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
        RAISE NOTICE 'Brak wystarczajacej ilosci zwierząt';
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

--========================================= DEFFERED TRIGGERY =========================================--

CREATE OR REPLACE FUNCTION check_stanowisko() RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pracownicy_stanowiska WHERE id_pracownika = NEW.id) THEN
        RAISE EXCEPTION 'nie ma stanowiska';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER czy_ma_stanowisko
AFTER INSERT OR UPDATE ON pracownicy
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_stanowisko();

CREATE OR REPLACE FUNCTION check_opiekun() RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM opiekunowie_gatunki WHERE id_gatunku = NEW.id) THEN
        RAISE EXCEPTION 'nie ma opiekuna';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER gatunki_opiekun
AFTER INSERT OR UPDATE ON gatunki
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_opiekun();

CREATE OR REPLACE FUNCTION check_gatunki() RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pracownicy_stanowiska ps JOIN stanowiska s ON ps.id_stanowiska = s.id WHERE ps.id_pracownika = NEW.id AND s.nazwa = 'opiekun') THEN
        RETURN NEW;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM opiekunowie_gatunki WHERE id_pracownika = NEW.id) THEN
        RAISE EXCEPTION 'nie ma gatunku pod opieka';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER opiekun_gatunki
AFTER INSERT OR UPDATE ON pracownicy
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_gatunki();

CREATE OR REPLACE FUNCTION check_sprzatacz() RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pracownicy_stanowiska ps JOIN stanowiska s ON ps.id_stanowiska = s.id WHERE s.nazwa = 'sprzatacz' AND ps.id_pracownika IN (SELECT id_pracownika FROM sprzatacze_wybiegi WHERE id_wybiegu = NEW.id)) THEN
        RAISE EXCEPTION 'kazdy wybieg musi miec  sprzatacza';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER wybiegi_cleaner_trigger
AFTER INSERT OR UPDATE ON wybiegi
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE check_sprzatacz();


