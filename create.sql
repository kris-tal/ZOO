--========================================= DROP IF EXISTS =========================================--

DROP TABLE IF EXISTS godziny_otwarcia CASCADE;
DROP TABLE IF EXISTS pracownicy CASCADE;
DROP TABLE IF EXISTS pracownicy_godziny_pracy CASCADE;
DROP TABLE IF EXISTS konta CASCADE;
DROP TABLE IF EXISTS stanowiska CASCADE;
DROP TABLE IF EXISTS strefy CASCADE;
DROP TABLE IF EXISTS wybiegi CASCADE;
DROP TABLE IF EXISTS gatunki CASCADE;
DROP TABLE IF EXISTS zwierzeta CASCADE;
DROP TABLE IF EXISTS pracownicy_stanowiska CASCADE;
DROP TABLE IF EXISTS trenerzy_gatunki CASCADE;
DROP TABLE IF EXISTS opiekunowie_gatunki CASCADE;
DROP TABLE IF EXISTS sprzatacze_wybiegi CASCADE;
DROP TABLE IF EXISTS popisy CASCADE;
DROP TABLE IF EXISTS plan_dnia CASCADE;
DROP VIEW IF EXISTS plan_24h CASCADE;
DROP VIEW IF EXISTS plan_godziny_otwarcia CASCADE;

--========================================= ZWYKLE FUNKCJE =========================================--


--========================================= RELACJE =========================================--

CREATE TABLE godziny_otwarcia (
    dzien_tygodnia INTEGER CHECK(dzien_tygodnia >= 1 AND dzien_tygodnia <= 7) NOT NULL,
    otwarcie TIME PRIMARY KEY,
    zamkniecie TIME CHECK(zamkniecie > otwarcie) NOT NULL,
    UNIQUE(dzien_tygodnia)
);

CREATE TABLE pracownicy (
    id SERIAL PRIMARY KEY,
    imie VARCHAR(40) NOT NULL,
    nazwisko VARCHAR(40) NOT NULL,
    pesel CHAR(11), CHECK(dobry_pesel(pesel)),
    haslo INTEGER, --to bedzie hash hasla ale hashowanie juz chyba w javie
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
    id_wybiegu INTEGER REFERENCES wybiegi(id) NOT NULL,
    licznosc INTEGER DEFAULT 0
);

CREATE TABLE zwierzeta (
    id SERIAL PRIMARY KEY,
    gatunek INTEGER REFERENCES gatunki(id) NOT NULL,
    imie VARCHAR(40), --to jest niepotrzebne w sumie ale slodko
    poziom_umiejetnosci INTEGER CHECK(poziom_umiejetnosci >= 0 AND poziom_umiejetnosci <= 10) NOT NULL
);

CREATE TABLE pracownicy_stanowiska (
    id_pracownika INTEGER REFERENCES pracownicy(id),
    id_stanowiska INTEGER REFERENCES stanowiska(id),
    PRIMARY KEY(id_pracownika, id_stanowiska)
);

CREATE OR REPLACE FUNCTION check_position() RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pracownicy_stanowiska WHERE id_pracownika = NEW.id) THEN
        RAISE EXCEPTION 'nie ma stanowiska';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER pracownicy_position_trigger
AFTER INSERT OR UPDATE ON pracownicy
FOR EACH ROW EXECUTE PROCEDURE check_position();

CREATE TABLE trenerzy_gatunki (
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
    id SERIAL PRIMARY KEY ,
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
-- po id wyszukuje czy jest w planie czy w historii

CREATE RULE historia_insert AS ON INSERT TO historia_plan_dnia DO INSTEAD NOTHING;
CREATE RULE historia_insert AS ON UPDATE TO historia_plan_dnia DO INSTEAD NOTHING;

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
END;
$historia_planu$ LANGUAGE plpgsql;

CREATE TRIGGER historia_planu BEFORE INSERT OR UPDATE ON plan_dnia
FOR EACH ROW EXECUTE FUNCTION historia_planu();

CREATE VIEW plan_24h AS
SELECT
data, pt.godzina_od, pt.godzina_do,
CASE WHEN id_sprzatacza IS NOT NULL THEN 'sprzatanie'
WHEN id_karmienia IS NOT NULL THEN 'karmienie'
ELSE 'popis' END AS rodzaj,
w.id AS wybieg, s.nazwa AS strefa, p.id AS id_popisu, pr.id AS id_trener, pr.imie, pr.nazwisko, gat.nazwa AS gatunek, min_ilosc, min_poziom_umiejetnosci, g.nazwa, g.id_wybiegu, g.licznosc

FROM plan_dnia pt
LEFT OUTER JOIN wybiegi w ON pt.id_sprzatacza = w.id
LEFT OUTER JOIN popisy p ON pt.id_popisu = p.id
LEFT OUTER JOIN gatunki g ON pt.id_karmienia = g.id
LEFT OUTER JOIN strefy s ON w.strefa = s.id
LEFT OUTER JOIN pracownicy pr ON p.trener = pr.id
LEFT OUTER JOIN gatunki gat ON p.gatunek = gat.id

ORDER BY data, godzina_od;

-- do poprawy co jak otwarcie/zamkniecie w trsakcie kar/sprz
CREATE VIEW plan_godziny_otwarcia AS
SELECT * FROM plan_24h
WHERE godzina_od > (SELECT otwarcie FROM godziny_otwarcia)
AND godzina_do < (SELECT zamkniecie FROM godziny_otwarcia)
ORDER BY data, godzina_od;

--========================================= TRIGGER FUNKCJE =========================================--




--========================================= INSERTY =========================================--
