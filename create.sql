--========================================= DROP IF EXISTS =========================================--

DROP TABLE IF EXISTS godziny_otwarcia CASCADE;
DROP TABLE IF EXISTS pracownicy CASCADE;
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
DROP TABLE IF EXISTS plan_tygodnia CASCADE;
DROP VIEW IF EXISTS plan_24h CASCADE;
DROP VIEW IF EXISTS plan_godziny_otwarcia CASCADE;

--========================================= ZWYKLE FUNKCJE =========================================--

------ sprawdzam czy pesel jest poprawny
CREATE OR REPLACE FUNCTION dobry_pesel() RETURNS TRIGGER AS $$
DECLARE
  tab NUMERIC[] := ARRAY[1, 3, 7, 9, 1, 3, 7, 9, 1, 3];
  suma NUMERIC := 0;
  i NUMERIC;
BEGIN
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
-------------------------------------------------------------------------------------


--========================================= RELACJE =========================================--

CREATE TABLE godziny_otwarcia (
    otwarcie TIME PRIMARY KEY,
    zamkniecie TIME CHECK(zamkniecie > otwarcie) NOT NULL
);

CREATE TABLE pracownicy (
    id SERIAL PRIMARY KEY,
    imie VARCHAR(40) NOT NULL,
    nazwisko VARCHAR(40) NOT NULL,
    pesel CHAR(11), CHECK(dobry_pesel(pesel)),
    haslo INTEGER, --to bedzie hash hasla ale hashowanie juz chyba w javie
    godzina_od TIME DEFAULT '8:00'::time NOT NULL ,        --nie ograniczamy godzinain pracy bo mozna pracowac w nocy
    godzina_do TIME DEFAULT '15:00'::time NOT NULL,
    UNIQUE(imie, nazwisko, pesel)
);

CREATE TRIGGER dobry_pesel
BEFORE INSERT OR UPDATE ON pracownicy
FOR EACH ROW EXECUTE PROCEDURE dobry_pesel();

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

CREATE TABLE nieobecnosci (
    id SERIAL PRIMARY KEY,
    id_pracownika INTEGER REFERENCES pracownicy(id) NOT NULL,
    dzien DATE NOT NULL,
    powod VARCHAR(200)
);

CREATE TABLE popisy (
    id SERIAL PRIMARY KEY ,
    trener INTEGER REFERENCES pracownicy(id) NOT NULL,
    gatunek INTEGER REFERENCES gatunki(id) NOT NULL,
    min_ilosc INTEGER CHECK(min_ilosc > 0),
    min_poziom_umiejetnosci INTEGER CHECK(min_ilosc >= 0 AND min_poziom_umiejetnosci <= 10)
);

CREATE TABLE plan_tygodnia (
    id SERIAL PRIMARY KEY,
    dzien_tygodnia INTEGER CHECK(dzien_tygodnia >= 1 AND dzien_tygodnia <= 7) NOT NULL,
    godzina_od TIME NOT NULL,
    godzina_do TIME NOT NULL,
    id_sprzatacza INTEGER REFERENCES wybiegi(id),
    id_karmienia INTEGER REFERENCES gatunki(id),
    id_popisu INTEGER REFERENCES popisy(id),
    CHECK(CASE WHEN id_sprzatacza IS NULL THEN 0 ELSE 1 END + CASE WHEN id_karmienia IS NULL THEN 0 ELSE 1 END + CASE WHEN id_popisu IS NULL THEN 0 ELSE 1 END = 1) --na razie to tak rozwiazalam ale nie wiem
);

CREATE VIEW plan_24h AS
SELECT
dzien_tygodnia, pt.godzina_od, pt.godzina_do,
CASE WHEN id_sprzatacza IS NOT NULL THEN 'sprzatanie'
WHEN id_karmienia IS NOT NULL THEN 'karmienie'
ELSE 'popis' END AS rodzaj,
w.id AS wybieg, s.nazwa AS strefa, p.id AS id_popisu, pr.id AS id_trener, pr.imie, pr.nazwisko, gat.nazwa AS gatunek, min_ilosc, min_poziom_umiejetnosci, g.nazwa, g.id_wybiegu, g.licznosc

FROM plan_tygodnia pt
LEFT OUTER JOIN wybiegi w ON pt.id_sprzatacza = w.id
LEFT OUTER JOIN popisy p ON pt.id_popisu = p.id
LEFT OUTER JOIN gatunki g ON pt.id_karmienia = g.id
LEFT OUTER JOIN strefy s ON w.strefa = s.id
LEFT OUTER JOIN pracownicy pr ON p.trener = pr.id
LEFT OUTER JOIN gatunki gat ON p.gatunek = gat.id

ORDER BY dzien_tygodnia, godzina_od;

-- do poprawy co jak otwarcie/zamkniecie w trsakcie kar/sprz
CREATE VIEW plan_godziny_otwarcia AS
SELECT * FROM plan_24h
WHERE godzina_od > (SELECT otwarcie FROM godziny_otwarcia)
AND godzina_do < (SELECT zamkniecie FROM godziny_otwarcia)
ORDER BY dzien_tygodnia, godzina_od;

--========================================= TRIGGER FUNKCJE =========================================--




--========================================= INSERTY =========================================--
