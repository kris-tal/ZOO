
CREATE TABLE pracownicy (
    id SERIAL PRIMARY KEY ,
    imie VARCHAR(40) NOT NULL ,
    nazwisko VARCHAR(40) NOT NULL ,
    pesel CHAR(11) CHECK(dobry_pesel(pesel)),
    godz_od TIME DEFAULT '8:00',
    godz_do TIME DEFAULT '16:00'
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
    licznosc INTEGER  --to  trzeba polaczyc ze zwierzetami zeby je jakos zliczalo
);

CREATE TABLE zwierzeta (
    id SERIAL PRIMARY KEY ,
    gatunek INTEGER REFERENCES gatunki(id) NOT NULL ,
    imie VARCHAR(40) , --to jest niepotrzebne w sumie ale slodki
    poz_umiej INTEGER CHECK(poz_umiej >= 0 AND poz_umiej <= 10) NOT NULL
);

UPDATE gatunki g
SET licznosc = (
    SELECT COUNT(z.id)
    FROM zwierzeta z
    WHERE z.gatunek = g.id
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

CREATE OR REPLACE FUNCTION dobry_pesel(pesel CHAR(11))
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