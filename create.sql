--========================================= DROP IF EXISTS =========================================--

DROP TABLE IF EXISTS godziny_otwarcia CASCADE;
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
    data_dodania DATE NOT NULL,  --dodac do insertow
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

-- tu nic nie mona dodawac ale regula nie zadziala

CREATE VIEW plan_24h AS
SELECT
data, pt.godzina_od, pt.godzina_do,
CASE WHEN id_sprzatacza IS NOT NULL THEN 'sprzatanie'
WHEN id_karmienia IS NOT NULL THEN 'karmienie'
ELSE 'popis' END AS rodzaj,
w.id AS wybieg, s.nazwa AS strefa, p.id AS id_popisu, pr.id AS id_trener, pr.imie, pr.nazwisko, gat.nazwa AS gatunek, min_ilosc, min_poziom_umiejetnosci, g.nazwa, g.id_wybiegu

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
WHERE godzina_od > (SELECT otwarcie FROM godziny_otwarcia WHERE dzien_tygodnia = extract(isodow from data))
AND godzina_do < (SELECT zamkniecie FROM godziny_otwarcia WHERE dzien_tygodnia = extract(isodow from data))
ORDER BY data, godzina_od;

--=================== histora ====================
CREATE TABLE historia_wybiegow AS SELECT *, NULL::date as data_usuniecia FROM wybiegi;
ALTER TABLE historia_wybiegow ADD PRIMARY KEY (id, data_usuniecia);

CREATE TABLE historia_zwierzat AS SELECT *, NULL::date, NULL::varchar[100]  as data_usuniecia FROM zwierzeta;
ALTER TABLE historia_zwierzat ADD PRIMARY KEY (id, data_usuniecia);

CREATE TABLE historia_pracownikow AS SELECT *, NULL::date as data_usuniecia FROM pracownicy;
ALTER TABLE historia_pracownikow ADD PRIMARY KEY (id, data_usuniecia);

--========================================= TRIGGER FUNKCJE =========================================--




--============================================== INSERTY =============================================--
--============================================== INDEKSY =============================================--
CREATE INDEX idx_zwierzeta_gatunek ON zwierzeta(gatunek);