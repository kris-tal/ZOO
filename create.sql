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
CREATE FUNCTION dobry_pesel(pesel CHAR(11))
RETURNS BOOLEAN AS $$
DECLARE
    kontrolna INTEGER;
    waga INTEGER[] := ARRAY[1, 3, 7, 9, 1, 3, 7, 9, 1, 3];
    suma INTEGER := 0;
BEGIN
    IF NOT pesel ~ '^[0-9]+$' THEN
        RETURN FALSE;
    END IF;

    IF LENGTH(pesel) != 11 THEN
        RETURN FALSE;
    END IF;

    FOR i IN 1..10 LOOP
        suma := suma + waga[i] * CAST(SUBSTRING(pesel FROM i FOR 1) AS INTEGER);
    END LOOP;

    kontrolna := (10 - (suma % 10)) % 10;

    IF kontrolna != CAST(SUBSTRING(pesel FROM 11 FOR 1) AS INTEGER) THEN
        RETURN FALSE;
    ELSE
        RETURN TRUE;
    END IF;
END;
$$ LANGUAGE PLPGSQL;
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


--========================================= INSERTY =========================================--
