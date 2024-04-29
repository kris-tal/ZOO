--========================================= DROP IF EXISTS =========================================--

DROP TABLE IF EXISTS godz_otwarcia CASCADE;
DROP TABLE IF EXISTS pracownicy CASCADE;
DROP TABLE IF EXISTS konta CASCADE;
DROP TABLE IF EXISTS stanowisko CASCADE;
DROP TABLE IF EXISTS strefy CASCADE;
DROP TABLE IF EXISTS wybiegi CASCADE;
DROP TABLE IF EXISTS gatunki CASCADE;
DROP TABLE IF EXISTS zwierzeta CASCADE;
DROP TABLE IF EXISTS prac_stan CASCADE;
DROP TABLE IF EXISTS tren_gat CASCADE;
DROP TABLE IF EXISTS opiek_gat CASCADE;
DROP TABLE IF EXISTS sprzat_wybieg CASCADE;
DROP TABLE IF EXISTS popisy CASCADE;
DROP TABLE IF EXISTS plan_tygodnia CASCADE;

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

CREATE TABLE godz_otwarcia (
    otwarcie TIME NOT NULL,
    zamkniecie TIME CHECK(zamkniecie > otwarcie)  NOT NULL
);

CREATE TABLE pracownicy (
    id SERIAL PRIMARY KEY ,
    imie VARCHAR(40) NOT NULL ,
    nazwisko VARCHAR(40) NOT NULL ,
    pesel CHAR(11), CHECK(dobry_pesel(pesel)) ,
    godz_od TIME DEFAULT '8:00'::time NOT NULL ,        --nie ograniczamy godzin pracy bo mozna pracowac w nocy
    godz_do TIME DEFAULT '15:00'::time NOT NULL,
    UNIQUE(imie, nazwisko, pesel)
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
    id_wybieg INTEGER REFERENCES wybiegi(id) NOT NULL ,
    licznosc INTEGER DEFAULT 0
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

CREATE TABLE sprzat_wybieg (
    id_prac INTEGER REFERENCES pracownicy(id) NOT NULL ,
    id_wybieg INTEGER REFERENCES wybiegi(id) NOT NULL ,
    PRIMARY KEY(id_prac, id_wybieg)
);

CREATE TABLE popisy (
    id SERIAL PRIMARY KEY ,
    trener INTEGER REFERENCES pracownicy(id) NOT NULL ,
    gatunek INTEGER REFERENCES gatunki(id) NOT NULL ,
    min_ilosc INTEGER CHECK(min_ilosc > 0) ,
    min_poz INTEGER CHECK(min_ilosc >= 0 AND min_poz <= 10)
);

CREATE TABLE plan_tygodnia (
    id SERIAL PRIMARY KEY ,
    dzien_tyg INTEGER CHECK(dzien_tyg >= 1 AND dzien_tyg <= 7) NOT NULL ,
    godz_od TIME NOT NULL ,
    godz_do TIME NOT NULL ,
    id_sprzat INTEGER REFERENCES wybiegi(id) ,
    id_karm INTEGER REFERENCES gatunki(id) ,
    id_popis INTEGER REFERENCES popisy(id) ,
    CHECK(CASE WHEN id_sprzat IS NULL THEN 0 ELSE 1 END + CASE WHEN id_karm IS NULL THEN 0 ELSE 1 END + CASE WHEN id_popis IS NULL THEN 0 ELSE 1 END = 1) --na razie to tak rozwiazalam ale nie wiem
);

-- na razie cos takiego
CREATE VIEW plan_szczegolowy AS
SELECT
dzien_tyg, pt.godz_od, pt.godz_do,
CASE WHEN id_sprzat IS NOT NULL THEN 'Sprzatanie'
WHEN id_karm IS NOT NULL THEN 'Karminie'
ELSE 'Popis' END AS rodzaj, 
w.id AS wybieg, s.nazwa AS strefa, p.id AS id_popisu, pr.id AS id_trener, pr.imie, pr.nazwisko, gat.nazwa AS gatunek, min_ilosc, min_poz, g.nazwa, g.id_wybieg, g.licznosc

FROM plan_tygodnia pt 
LEFT OUTER JOIN wybiegi w ON pt.id_sprzat = w.id
LEFT OUTER JOIN popisy p ON pt.id_popis = p.id
LEFT OUTER JOIN gatunki g ON pt.id_karm = g.id
LEFT OUTER JOIN strefy s ON w.strefa = s.id
LEFT OUTER JOIN pracownicy pr ON p.trener = pr.id
LEFT OUTER JOIN gatunki gat ON p.gatunek = gat.id

ORDER BY dzien_tyg, godz_od;

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
CREATE FUNCTION check_godz_otwarcia() RETURNS TRIGGER
AS $$
BEGIN
    IF NEW.id_popis IS NULL THEN RETURN NEW; END IF;        --dla srzatania i karmienia nie sprawdzamy
    IF NEW.godz_od < (SELECT otwarcie FROM godz_otwarcia LIMIT 1) THEN
        RAISE EXCEPTION 'Godzina rozpoczęcia musi być po godzinie otwarcia';
    END IF;

    IF NEW.godz_do > (SELECT zamkniecie FROM godz_otwarcia LIMIT 1) THEN
        RAISE EXCEPTION 'Godzina zakończenia musi być przed godziną zamknięcia';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER akt_popisow
    BEFORE INSERT OR UPDATE ON plan_tygodnia
    FOR EACH ROW EXECUTE FUNCTION check_godz_otwarcia();
-------------------------------------------------------------------------------------

-- musze zrobic to w druga strone - jak updatuje godz otwarcia to musze sprawdzic wszystko w planie dnia czy pasuje
-- i albo nie pozwolic zmienic albo usunac
------ sprawdzam czy nowe godziny otwarcia nie koliduja z jakimis popisami
CREATE FUNCTION check_godz_popisow() RETURNS TRIGGER
AS $$
BEGIN
    IF EXISTS (
        SELECT true
        FROM plan_tygodnia
        WHERE id_popis IS NOT NULL
        AND (godz_od < NEW.otwarcie OR godz_do > NEW.zamkniecie)
    ) THEN
        RAISE EXCEPTION 'Nowa godzina rozpoczęcia koliduje z istniejącymi popisami';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER akt_godz_otwarcia
    BEFORE INSERT OR UPDATE ON godz_otwarcia
    FOR EACH ROW EXECUTE FUNCTION check_godz_popisow();
-------------------------------------------------------------------------------------
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


--========================================= INSERTY =========================================--
INSERT INTO godz_otwarcia (otwarcie, zamkniecie) VALUES
('8:00'::time, '19:00'::time);

INSERT INTO pracownicy (imie, nazwisko, pesel, godz_od, godz_do) VALUES
('Józef', 'Sanetra', '85090127679', '3:00', '10:00'),
('Blanka', 'Kijas', '25011909517', '3:00', '11:00'),
('Dagmara', 'Wolff', '03073139598', '11:00', '18:00'),
('Elżbieta', 'Kuszyk', '20040926328', '13:00', '19:00'),
('Anastazja', 'Kozon', '76042421194', '8:00', '15:00'),
('Alex', 'Schubert', '14121654439', '3:00', '13:00'),
('Maurycy', 'Szkaradek', '82112627751', '11:00', '21:00'),
('Tobiasz', 'Wota', '62120872392', '8:00', '17:00'),
('Ksawery', 'Tórz', '66050173897', '2:00', '12:00'),
('Sandra', 'Pilarek', '29092312288', '2:00', '8:00'),
('Aleks', 'Szram', '56033139231', '9:00', '19:00'),
('Arkadiusz', 'Drygała', '18020918285', '7:00', '13:00'),
('Marianna', 'Wojtczuk', '90030960159', '9:00', '17:00'),
('Krystian', 'Tarasek', '09030433013', '1:00', '9:00'),
('Ewelina', 'Nagel', '66012029758', '11:00', '17:00'),
('Agnieszka', 'Huber', '83060308367', '9:00', '19:00'),
('Gustaw', 'Policht', '88060750510', '9:00', '19:00'),
('Ignacy', 'Władyka', '23012955612', '3:00', '10:00'),
('Konstanty', 'Kolanko', '01041115289', '0:00', '10:00'),
('Juliusz', 'Rećko', '64011456766', '1:00', '9:00'),
('Grzegorz', 'Pietrasz', '61051369423', '5:00', '15:00'),
('Dominik', 'Burchardt', '71051893086', '8:00', '15:00'),
('Jan', 'Zyzik', '38030224017', '9:00', '17:00'),
('Roksana', 'Kiszczak', '59010475362', '6:00', '14:00'),
('Bruno', 'Prawdzik', '64052678679', '7:00', '17:00'),
('Marcelina', 'Dub', '14021291543', '5:00', '12:00'),
('Ewelina', 'Durlik', '11081347072', '2:00', '10:00'),
('Kazimierz', 'Okła', '29120886477', '2:00', '9:00'),
('Krystyna', 'Kazubek', '23060525919', '11:00', '19:00'),
('Albert', 'Buszko', '68110981330', '3:00', '9:00'),
('Paweł', 'Juszczuk', '99062212946', '13:00', '19:00'),
('Alex', 'Dziewior', '31070395295', '10:00', '16:00'),
('Julian', 'Strzała', '97012059553', '8:00', '17:00'),
('Krzysztof', 'Palej', '84052251058', '0:00', '8:00'),
('Marika', 'Księżak', '07092484026', '10:00', '20:00'),
('Malwina', 'Dub', '15102040441', '10:00', '18:00'),
('Anna Maria', 'Rabiej', '48041453353', '12:00', '22:00'),
('Hubert', 'Gołofit', '22100365177', '11:00', '21:00'),
('Albert', 'Serwach', '54012288985', '6:00', '13:00'),
('Ryszard', 'Ubysz', '07071029277', '12:00', '18:00'),
('Michał', 'Mydlarz', '65113092320', '10:00', '17:00'),
('Angelika', 'Godzwon', '07021331865', '0:00', '7:00'),
('Błażej', 'Nazarewicz', '55070526349', '10:00', '18:00'),
('Józef', 'Gasek', '30030146388', '10:00', '19:00'),
('Marianna', 'Cich', '56121636084', '1:00', '11:00'),
('Aniela', 'Lepak', '89022662427', '7:00', '15:00'),
('Liwia', 'Chalimoniuk', '21112700174', '13:00', '22:00'),
('Ernest', 'Rezmer', '01102702887', '13:00', '23:00'),
('Hubert', 'Filiks', '39013036751', '1:00', '7:00'),
('Sylwia', 'Dybiec', '72040476495', '10:00', '19:00'),
('Nikodem', 'Niedźwiadek', '81042846098', '9:00', '18:00'),
('Justyna', 'Bieszke', '21120843070', '2:00', '8:00'),
('Aleks', 'Granat', '18101235746', '11:00', '20:00'),
('Aurelia', 'Smektała', '52032576606', '8:00', '15:00'),
('Aniela', 'Wyskiel', '11062822509', '4:00', '12:00'),
('Marek', 'Mirończuk', '17062497141', '2:00', '8:00'),
('Marek', 'Wałaszek', '79012474305', '13:00', '20:00'),
('Kazimierz', 'Stebel', '08032056466', '13:00', '22:00'),
('Filip', 'Kołaczyk', '13030386196', '1:00', '7:00'),
('Angelika', 'Kulus', '91121205964', '7:00', '17:00'),
('Lidia', 'Golczyk', '50060567285', '10:00', '17:00'),
('Aleksander', 'Dzieża', '99120178012', '10:00', '19:00'),
('Kajetan', 'Dobrosz', '12011520080', '5:00', '14:00'),
('Mikołaj', 'Pyrkosz', '75022181567', '4:00', '12:00'),
('Karol', 'Cieciora', '65021926845', '2:00', '12:00'),
('Alan', 'Budych', '42022002392', '3:00', '9:00'),
('Wojciech', 'Glegoła', '03061707705', '1:00', '7:00'),
('Julita', 'Prażuch', '45041055264', '9:00', '18:00'),
('Nela', 'Kultys', '68020211840', '5:00', '11:00'),
('Aleksander', 'Poreda', '28112702793', '13:00', '22:00'),
('Sandra', 'Biernacik', '14051589351', '7:00', '15:00'),
('Blanka', 'Rusnak', '20033170433', '8:00', '18:00'),
('Marcelina', 'Tonder', '74010391155', '1:00', '8:00'),
('Krzysztof', 'Dycha', '24092125018', '8:00', '17:00'),
('Elżbieta', 'Koźlak', '49122042945', '4:00', '12:00'),
('Agnieszka', 'Porzucek', '87051373475', '12:00', '21:00'),
('Ryszard', 'Żołądź', '59050212194', '2:00', '9:00'),
('Andrzej', 'Jędral', '22030968059', '8:00', '15:00'),
('Artur', 'Chaba', '00052118445', '4:00', '14:00'),
('Kornelia', 'Szuta', '72082279588', '3:00', '9:00'),
('Albert', 'Roter', '72080465938', '9:00', '17:00'),
('Ewa', 'Frydrychowicz', '57041458183', '11:00', '17:00'),
('Natasza', 'Dzienis', '96041138796', '11:00', '21:00'),
('Julianna', 'Cieciora', '47070518039', '7:00', '13:00'),
('Jan', 'Jenek', '66080207739', '6:00', '13:00'),
('Oskar', 'Pyda', '36071297645', '11:00', '17:00'),
('Kornelia', 'Wośko', '34031812374', '5:00', '15:00'),
('Cyprian', 'Ernst', '40071564603', '6:00', '14:00'),
('Urszula', 'Giec', '29082928813', '4:00', '12:00'),
('Piotr', 'Siergiej', '58092691992', '2:00', '10:00'),
('Fryderyk', 'Hanc', '14090335094', '4:00', '14:00'),
('Piotr', 'Godyń', '96010650933', '7:00', '14:00'),
('Kazimierz', 'Durlej', '12052944791', '13:00', '21:00'),
('Wojciech', 'Balas', '07010877165', '2:00', '9:00'),
('Nela', 'Dudczak', '82072026447', '5:00', '14:00'),
('Rozalia', 'Kapałka', '03042945201', '4:00', '14:00'),
('Anastazja', 'Truchel', '03050925147', '3:00', '12:00'),
('Natasza', 'Kożuszek', '79041885011', '2:00', '11:00'),
('Kornel', 'Hamera', '82081887185', '10:00', '18:00'),
('Janina', 'Fiołka', '37070524008', '1:00', '8:00');

INSERT INTO stanowisko (nazwa) VALUES
('zarzadca'),
('sprzatacz'),
('trener'),
('opiekun');

INSERT INTO strefy (nazwa) VALUES
('afrykańska sawanna'),
('dżungla'),
('pustynia'),
('oceanarium'),
('terrarium'),
('farma'),
('ptaszarnia');

INSERT INTO wybiegi (strefa) VALUES
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7),
(1),
(2),
(3),
(4),
(5),
(6),
(7);

INSERT INTO gatunki (nazwa, id_wybieg) VALUES
('żbik', 57),
('szczur', 23),
('jeleń', 4),
('orangutan', 72),
('hipo', 35),
('żłów', 10),
('gołąb', 68),
('motyl', 49),
('gibon', 19),
('bawół', 75),
('koala', 6),
('szop', 31),
('szympans', 42),
('tukan', 77),
('kormoran', 53),
('kangur', 14),
('lis', 20),
('żaba', 63),
('wieloryb', 9),
('żółw', 46),
('żubr', 28),
('hiena', 67),
('tygrys', 5),
('żuraw', 74),
('emu', 30),
('jeż', 40),
('orzeł', 61),
('wąż', 36),
('kanarek', 16),
('dzik', 71),
('chomik', 55),
('gepard', 3),
('zebra', 47),
('lew', 34),
('alpaka', 50),
('zając', 70),
('ryś', 41),
('kaczka', 52),
('wróbel', 12),
('jagnię', 69),
('pstrąg', 65),
('mysz', 78),
('ośmiornica', 1),
('antylopa', 58),
('rekin', 22),
('flaming', 7),
('małpa', 32),
('bocian', 45),
('wielbłąd', 60),
('kiwi', 8),
('kot', 62),
('puchacz', 25),
('koń', 79),
('jaszczurka', 59),
('nutria', 38),
('słoń', 39),
('ropucha', 37),
('krokodyl', 66),
('lama', 54),
('sowa', 27),
('żuk', 17),
('mrówkojad', 33),
('łoś', 51),
('osioł', 15),
('pies', 26),
('żmija', 76),
('nosorożec', 24),
('pingwin', 11),
('kura', 2),
('surikata', 64),
('skunks', 44),
('borsuk', 48),
('kruk', 73),
('papuga', 29),
('foka', 56),
('panda', 18),
('delfin', 80),
('mors', 43),
('królik', 21),
('kameleon', 13),
('żyrafa', 3),
('sokół', 3);


INSERT INTO prac_stan (id_prac, id_stan) VALUES
(79, 3),
(65, 4),
(90, 3),
(56, 1),
(37, 1),
(69, 1),
(16, 3),
(51, 2),
(7, 2) ,
(38, 2),
(44, 2),
(43, 4),
(81, 3),
(32, 1),
(21, 2),
(25, 3),
(88, 4),
(23, 1),
(82, 2),
(73, 3),
(34, 2),
(62, 3),
(52, 2),
(66, 3),
(50, 2),
(24, 2),
(68, 3),
(49, 1),
(86, 3),
(89, 1),
(98, 1),
(77, 3),
(99, 2),
(40, 2),
(60, 4),
(94, 2),
(83, 4),
(92, 4),
(64, 2),
(36, 1),
(76, 4),
(22, 1),
(100, 4),
(91, 1),
(93, 1),
(71, 2),
(58, 3),
(6, 2),
(42, 4),
(20, 3),
(75, 3),
(84, 3),
(33, 3),
(31, 4),
(11, 3),
(87, 2),
(80, 1),
(30, 1),
(8, 1),
(96, 4),
(9, 2),
(35, 2),
(72, 3),
(19, 2),
(27, 3),
(97, 2),
(3, 4),
(26, 2),
(17, 4),
(10, 4),
(55, 2),
(18, 3),
(67, 3),
(74, 3),
(48, 1),
(57, 4),
(28, 4),
(59, 2),
(63, 3),
(95, 4),
(12, 2),
(2, 2),
(1, 4),
(70, 2),
(61, 2),
(85, 2),
(5, 2),
(78, 4),
(14, 1),
(29, 3),
(45, 2),
(15, 4),
(47, 4),
(54, 1),
(4, 1),
(41, 1),
(53, 1),
(46, 2),
(39, 2),
(13, 1),
(91, 2),
(50, 4),
(29, 4),
(84, 2),
(86, 2),
(75, 2),
(96, 3),
(60, 3),
(79, 4),
(51, 3),
(47, 2),
(73, 2),
(57, 1),
(83, 1),
(66, 1),
(26, 1),
(34, 1),
(17, 3),
(62, 4),
(64, 4),
(46, 4),
(31, 2),
(42, 3),
(59, 4);



