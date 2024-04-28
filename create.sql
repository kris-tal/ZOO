--========================================= ZWYKLE FUNKCJE =========================================--

------ sprawdzam czy pesel jest poprawny
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

CREATE TABLE godz_otwarcia (
    otwarcie TIME NOT NULL,
    zamkniecie TIME NOT NULL
);

CREATE TABLE pracownicy (
    id SERIAL PRIMARY KEY ,
    imie VARCHAR(40) NOT NULL ,
    nazwisko VARCHAR(40) NOT NULL ,
    pesel CHAR(11) CHECK(dobry_pesel(pesel)) ,
    godz_od TIME DEFAULT '8:00'::time NOT NULL ,        --nie ograniczamy godzin pracy bo mozna pracowac w nocy
    godz_do TIME DEFAULT '15:00'::time NOT NULL
);

CREATE TABLE konta (
    id_prac INTEGER PRIMARY KEY REFERENCES pracownicy(id) NOT NULL ,
    haslo INTEGER --to bedzie hash hasla ale hashowanie juz chyba nie w psql
);

CREATE TABLE stanowisko (
    id SERIAL PRIMARY KEY ,
    nazwa CHAR(20) CHECK(nazwa = 'zarzadca' OR nazwa = 'sprzatacz' OR nazwa = 'trener' OR nazwa = 'opiekun') NOT NULL
);

CREATE TABLE strefy (
    id SERIAL PRIMARY KEY ,
    nazwa VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE wybiegi (
    id SERIAL PRIMARY KEY ,
    strefa INTEGER REFERENCES strefy(id) NOT NULL
);

CREATE TABLE gatunki (
    id SERIAL PRIMARY KEY ,
    nazwa VARCHAR(100) NOT NULL UNIQUE,
    wybieg INTEGER REFERENCES wybiegi(id) NOT NULL ,
    licznosc INTEGER
);

CREATE TABLE zwierzeta (
    id SERIAL PRIMARY KEY ,
    gatunek INTEGER REFERENCES gatunki(id) NOT NULL ,
    imie VARCHAR(40) , --to jest niepotrzebne w sumie ale slodko
    poz_umiej INTEGER CHECK(poz_umiej >= 0 AND poz_umiej <= 10) NOT NULL
);

CREATE TABLE prac_stan (
    id_prac INTEGER REFERENCES pracownicy(id) NOT NULL ,
    id_stan INTEGER REFERENCES stanowisko(id) NOT NULL ,
    UNIQUE(id_prac, id_stan)
);

CREATE TABLE tren_gat (
    id_prac INTEGER REFERENCES pracownicy(id) NOT NULL ,
    id_gat INTEGER REFERENCES gatunki(id) NOT NULL ,
    PRIMARY KEY(id_prac, id_gat)
);

CREATE TABLE opiek_gat (
    id_prac INTEGER REFERENCES pracownicy(id) NOT NULL ,
    id_gat INTEGER REFERENCES gatunki(id) NOT NULL ,
    PRIMARY KEY(id_prac, id_gat)
);

CREATE TABLE sprzat_klat (
    id_prac INTEGER REFERENCES pracownicy(id) NOT NULL ,
    id_wybieg INTEGER REFERENCES wybiegi(id) NOT NULL ,
    PRIMARY KEY(id_prac, id_wybieg)
);

CREATE TABLE popisy (
    id SERIAL PRIMARY KEY ,
    trener INTEGER REFERENCES pracownicy(id) NOT NULL ,
    czas_trwania INTERVAL NOT NULL ,
    gatunek INTEGER REFERENCES gatunki(id) NOT NULL ,
    min_ilosc INTEGER CHECK(min_ilosc > 0) ,
    min_poz INTEGER CHECK(min_ilosc >= 0 AND min_poz <= 10)
);

CREATE TABLE plan_tygodnia (
    id SERIAL PRIMARY KEY ,
    dzien_tyg INTEGER CHECK(dzien_tyg >= 1 AND dzien_tyg <= 7) NOT NULL ,
    godz_od TIME NOT NULL ,
    godz_do TIME NOT NULL ,
    id_sprzat INTEGER ,
    id_karm INTEGER ,
    id_popis INTEGER ,
    CHECK(CASE WHEN id_sprzat IS NULL THEN 0 ELSE 1 END + CASE WHEN id_karm IS NULL THEN 0 ELSE 1 END + CASE WHEN id_popis IS NULL THEN 0 ELSE 1 END = 1) --na razie to tak rozwiazalam ale nie wiem
);


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
------ sprawdzam czy aktywnosc nie jest poza czasem otwarcia zoo
CREATE FUNCTION check_godz_otwarcia() RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.godz_od < (SELECT otwarcie FROM godz_otwarcia LIMIT 1) THEN
        RAISE EXCEPTION 'Godzina rozpoczęcia musi być po godzinie otwarcia';
    END IF;

    IF NEW.godz_do > (SELECT zamkniecie FROM godz_otwarcia LIMIT 1) THEN
        RAISE EXCEPTION 'Godzina zakończenia musi być przed godziną zamknięcia';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER akt_godz_otwarcia
    BEFORE INSERT OR UPDATE ON plan_tygodnia
    FOR EACH ROW EXECUTE FUNCTION check_godz_otwarcia();
-------------------------------------------------------------------------------------

-- musze zrobic to w druga strone - jak updatuje godz otwarcia to musze sprawdzic wszystko w planie dnia czy pasuje
-- i albo nie pozwolic zmienic albo usunac

------ pilnuje czy jest tylko jedna krotka w relacji godz_otwarcia
CREATE OR REPLACE FUNCTION jeden() RETURNS TRIGGER
AS $$
DECLARE
    licznik INTEGER;
BEGIN
    SELECT COUNT(*) INTO licznik FROM godz_otwarcia;

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
    BEFORE INSERT OR DELETE ON godz_otwarcia
    FOR EACH ROW EXECUTE FUNCTION jeden();

-------------------------------------------------------------------------------------