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
DROP VIEW IF EXISTS plan_szczegolowy CASCADE;

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
    id_prac INTEGER PRIMARY KEY REFERENCES pracownicy(id),
    haslo INTEGER, --to bedzie hash hasla ale hashowanie juz chyba w javie
    PRIMARY KEY (id_prac, haslo)
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
        AND ((godz_od < NEW.otwarcie) OR (godz_do > NEW.zamkniecie))
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

INSERT INTO konta (id_prac, haslo) VALUES
(1, 930565),
(2, 760668),
(3, 610602),
(4, 624866),
(5, 274991),
(6, 694958),
(7, 362954),
(8, 80502),
(9, 134338),
(10, 637364),
(11, 47461),
(12, 874364),
(13, 371146),
(14, 622042),
(15, 20657),
(16, 244014),
(17, 293865),
(18, 706307),
(19, 171369),
(20, 92900),
(21, 406719),
(22, 968536),
(23, 122018),
(24, 948333),
(25, 142882),
(26, 861780),
(27, 852153),
(28, 378330),
(29, 16801),
(30, 213187),
(31, 426629),
(32, 944582),
(33, 688297),
(34, 890332),
(35, 29980),
(36, 9657),
(37, 586329),
(38, 746769),
(39, 808040),
(40, 541219),
(41, 55272),
(42, 54414),
(43, 187024),
(44, 993334),
(45, 34006),
(46, 292135),
(47, 723458),
(48, 355743),
(49, 112235),
(50, 394978),
(51, 113118),
(52, 56414),
(53, 621314),
(54, 260184),
(55, 735069),
(56, 988819),
(57, 435184),
(58, 16010),
(59, 869184),
(60, 584062),
(61, 778159),
(62, 772659),
(63, 45282),
(64, 722908),
(65, 564423),
(66, 704907),
(67, 761490),
(68, 484747),
(69, 256544),
(70, 24143),
(71, 915504),
(72, 321447),
(73, 321628),
(74, 568728),
(75, 679163),
(76, 898155),
(77, 954469),
(78, 937073),
(79, 502012),
(80, 206045),
(81, 260773),
(82, 599594),
(83, 592695),
(84, 439548),
(85, 885442),
(86, 109555),
(87, 590428),
(88, 97202),
(89, 260086),
(90, 950816),
(91, 48579),
(92, 414921),
(93, 785526),
(94, 188095),
(95, 678178),
(96, 84386),
(97, 729910),
(98, 991629),
(99, 326436),
(100, 894919);

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

INSERT INTO zwierzeta (gatunek, imie, poz_umiej) VALUES
(32, 'Lauren', 2),
(9, 'Tracey', 0),
(64, 'Danielle', 9),
(9, 'Deanna', 4),
(60, 'Brian', 8),
(57, 'Tina', 2),
(61, 'Rebecca', 8),
(48, 'Sophia', 9),
(51, 'David', 6),
(50, 'Melissa', 7),
(44, 'Elizabeth', 4),
(26, 'Gary', 3),
(46, 'Brandon', 9),
(21, 'Ryan', 9),
(21, 'Candace', 10),
(63, 'Julie', 5),
(15, 'Patrick', 7),
(61, 'Emily', 7),
(35, 'Amanda', 5),
(13, 'Shannon', 5),
(68, 'Brenda', 2),
(12, 'William', 2),
(32, 'Sandra', 4),
(5, 'Donald', 9),
(73, 'Andrew', 5),
(3, 'Debra', 0),
(78, 'Paul', 10),
(70, 'Heather', 1),
(1, 'Jose', 8),
(12, 'Julie', 0),
(29, 'Whitney', 1),
(53, 'Lauren', 5),
(82, 'Jason', 8),
(75, 'Kevin', 3),
(57, 'Jeanne', 1),
(54, 'Angela', 6),
(16, 'Dakota', 9),
(71, 'Kristy', 4),
(16, 'Lisa', 9),
(9, 'Melissa', 6),
(50, 'Mary', 6),
(28, 'Eric', 4),
(73, 'Michael', 5),
(5, 'Sandra', 8),
(61, 'Derrick', 1),
(48, 'Jacob', 1),
(48, 'Linda', 6),
(71, 'Jennifer', 6),
(56, 'Jennifer', 10),
(53, 'Samantha', 0),
(23, 'Joshua', 8),
(29, 'Richard', 0),
(27, 'Andrea', 5),
(39, 'Timothy', 0),
(32, 'Brittany', 9),
(39, 'Holly', 2),
(71, 'Megan', 7),
(32, 'Michael', 9),
(28, 'Michelle', 10),
(17, 'Crystal', 3),
(49, 'Jim', 2),
(54, 'Alisha', 3),
(55, 'Steve', 5),
(19, 'Valerie', 8),
(57, 'Joseph', 10),
(81, 'Heidi', 1),
(23, 'Debra', 0),
(25, 'Timothy', 3),
(44, 'Michael', 6),
(64, 'Yesenia', 9),
(49, 'Lisa', 6),
(69, 'Kimberly', 9),
(53, 'Stacy', 3),
(62, 'Laurie', 7),
(28, 'Paula', 2),
(62, 'Jamie', 6),
(26, 'Christopher', 7),
(20, 'Eric', 7),
(25, 'Linda', 3),
(6, 'Sherry', 5),
(23, 'Edward', 8),
(59, 'Andrea', 2),
(47, 'Travis', 2),
(17, 'Jorge', 7),
(38, 'April', 1),
(78, 'Ryan', 6),
(36, 'Richard', 8),
(70, 'Gary', 6),
(59, 'Gilbert', 8),
(59, 'Nathan', 0),
(17, 'Patricia', 0),
(39, 'Samantha', 1),
(56, 'Cynthia', 2),
(69, 'Tyrone', 8),
(34, 'Donna', 7),
(43, 'Brian', 1),
(2, 'Christine', 2),
(78, 'Douglas', 4),
(13, 'Mary', 5),
(39, 'Denise', 4),
(73, 'Michael', 9),
(35, 'Maria', 6),
(22, 'Yvonne', 10),
(56, 'Kathleen', 2),
(60, 'Victor', 0),
(58, 'Craig', 7),
(76, 'Antonio', 6),
(77, 'Ryan', 6),
(29, 'Stephen', 4),
(54, 'Taylor', 7),
(79, 'Kimberly', 6),
(58, 'Kenneth', 1),
(36, 'Mark', 6),
(28, 'Tracie', 5),
(48, 'Kyle', 8),
(65, 'Gary', 1),
(14, 'Lynn', 8),
(51, 'Julia', 1),
(54, 'Justin', 0),
(2, 'Sarah', 7),
(30, 'Jessica', 4),
(54, 'Gloria', 5),
(73, 'Barbara', 3),
(68, 'Miranda', 1),
(43, 'Joseph', 1),
(5, 'Valerie', 2),
(15, 'Hannah', 5),
(27, 'Kelly', 0),
(63, 'Donna', 2),
(29, 'James', 1),
(63, 'Taylor', 7),
(17, 'Victoria', 1),
(23, 'Steven', 5),
(63, 'Scott', 0),
(81, 'Stephanie', 5),
(52, 'Heidi', 7),
(43, 'Elizabeth', 4),
(32, 'Vanessa', 10),
(10, 'Tracy', 4),
(42, 'Anthony', 0),
(6, 'Katie', 1),
(59, 'Andrew', 0),
(18, 'Charlotte', 7),
(81, 'Stephen', 2),
(22, 'Stephanie', 8),
(47, 'Jeremy', 9),
(49, 'Vanessa', 0),
(24, 'Theresa', 4),
(18, 'Ashley', 1),
(41, 'Nicole', 8),
(74, 'Jessica', 9),
(35, 'Chad', 3),
(31, 'Nathaniel', 1),
(15, 'Audrey', 10),
(60, 'Jeffrey', 10),
(35, 'Daniel', 2),
(14, 'Donald', 2),
(43, 'Angela', 0),
(12, 'Daniel', 7),
(79, 'Lance', 2),
(29, 'Rebecca', 7),
(24, 'Mary', 4),
(12, 'Glenda', 4),
(2, 'Jessica', 0),
(36, 'Tyler', 4),
(28, 'Michele', 7),
(49, 'Randy', 2),
(14, 'Richard', 0),
(55, 'Nicholas', 5),
(44, 'Debra', 9),
(60, 'Tracy', 5),
(24, 'Elizabeth', 8),
(17, 'Brian', 5),
(57, 'Paula', 2),
(12, 'Brenda', 5),
(77, 'Michelle', 8),
(75, 'Joseph', 2),
(52, 'Robert', 8),
(3, 'Richard', 1),
(79, 'Matthew', 1),
(47, 'Paul', 9),
(76, 'Angela', 9),
(29, 'Robert', 9),
(12, 'Brian', 0),
(66, 'Austin', 0),
(76, 'Lori', 2),
(43, 'Christopher', 4),
(20, 'Marcia', 2),
(49, 'Michael', 8),
(10, 'Debra', 1),
(36, 'Glenn', 8),
(45, 'Michael', 1),
(2, 'Nicole', 5),
(27, 'Jennifer', 0),
(56, 'Michael', 10),
(67, 'Denise', 3),
(18, 'Jamie', 1),
(61, 'Rachael', 5),
(52, 'Robert', 6),
(17, 'John', 8),
(28, 'Isaiah', 3),
(30, 'James', 3),
(81, 'Randy', 8),
(79, 'Adam', 8),
(9, 'Mary', 1),
(79, 'Jill', 2),
(73, 'Stacey', 1),
(55, 'Adrian', 0),
(64, 'Roy', 4),
(21, 'Gregory', 2),
(46, 'Christopher', 7),
(37, 'Lauren', 1),
(21, 'Jon', 6),
(68, 'Mark', 3),
(50, 'Rebecca', 3),
(82, 'Savannah', 7),
(12, 'Madison', 7),
(64, 'Thomas', 5),
(81, 'Natasha', 0),
(41, 'Dawn', 1),
(7, 'David', 6),
(56, 'Mary', 0),
(62, 'Bianca', 8),
(14, 'Kristen', 2),
(71, 'William', 7),
(30, 'William', 1),
(72, 'Derrick', 1),
(46, 'Clarence', 3),
(28, 'Michael', 5),
(63, 'Daniel', 4),
(55, 'Kim', 9),
(10, 'Kevin', 6),
(4, 'Kevin', 9),
(6, 'Christopher', 6),
(22, 'Christina', 5),
(40, 'John', 7),
(62, 'Steven', 7),
(45, 'Kevin', 0),
(79, 'Danielle', 6),
(2, 'Michael', 6),
(37, 'Kimberly', 7),
(11, 'Ronnie', 1),
(43, 'Gregory', 10),
(69, 'Kari', 1),
(42, 'Claudia', 10),
(9, 'Tiffany', 2),
(35, 'Mary', 1),
(36, 'Stephen', 7),
(57, 'Donna', 2),
(67, 'Steven', 10),
(64, 'Shelia', 0),
(49, 'Steven', 0),
(71, 'Jennifer', 8),
(51, 'Melissa', 0),
(14, 'Gabrielle', 3),
(33, 'Andrea', 3),
(17, 'Stacy', 4),
(26, 'Jamie', 0),
(17, 'Matthew', 6),
(63, 'Matthew', 4),
(4, 'Samuel', 2),
(29, 'Rachel', 3),
(47, 'James', 1),
(1, 'Angelica', 0),
(1, 'Erin', 3),
(70, 'Scott', 6),
(74, 'Matthew', 8),
(37, 'Jacob', 3),
(43, 'Vickie', 5),
(38, 'Tammy', 3),
(60, 'Miguel', 4),
(7, 'Jeremy', 4),
(73, 'Emily', 10),
(7, 'Donna', 0),
(63, 'Lauren', 10),
(30, 'Mary', 4),
(70, 'Julie', 5),
(45, 'Patrick', 1),
(59, 'Wayne', 9),
(81, 'Eric', 5),
(4, 'Sheila', 2),
(39, 'Lawrence', 2),
(45, 'Alison', 5),
(24, 'Carlos', 1),
(51, 'Laurie', 5),
(33, 'Karen', 4),
(78, 'Joanna', 5),
(74, 'Brandy', 1),
(27, 'Samantha', 6),
(11, 'Nancy', 3),
(29, 'Pamela', 7),
(64, 'Amanda', 4),
(12, 'John', 9),
(75, 'Jeff', 5),
(27, 'Jordan', 3),
(11, 'Deborah', 2),
(3, 'Kathryn', 4),
(12, 'Sherry', 4),
(1, 'Geoffrey', 9),
(61, 'Crystal', 2),
(21, 'Yvonne', 6),
(33, 'Brandy', 6),
(4, 'Claire', 10),
(76, 'Jeffrey', 10),
(55, 'Joseph', 2),
(50, 'Dorothy', 7),
(6, 'Cynthia', 0),
(3, 'Thomas', 4),
(59, 'Juan', 2),
(67, 'Douglas', 3),
(25, 'David', 5),
(39, 'Travis', 0),
(65, 'Dawn', 2),
(82, 'David', 8),
(30, 'Jessica', 7),
(8, 'Steven', 1),
(29, 'Joseph', 7),
(53, 'Julie', 9),
(31, 'Nicholas', 7),
(12, 'Michael', 7),
(8, 'Kerri', 0),
(69, 'Ryan', 10),
(46, 'Pamela', 1),
(75, 'Randall', 4),
(30, 'Jacqueline', 8),
(61, 'Juan', 3),
(33, 'Danny', 5),
(21, 'Carlos', 3),
(64, 'Tracy', 2),
(34, 'Tiffany', 10),
(9, 'Melinda', 5),
(66, 'Jimmy', 10),
(22, 'Steven', 2),
(82, 'Jill', 8),
(37, 'Jorge', 2),
(81, 'Michael', 8),
(3, 'Julia', 7),
(68, 'Tammy', 3),
(65, 'Melissa', 2),
(68, 'Sheila', 3),
(68, 'Philip', 2),
(74, 'Erin', 5),
(22, 'Monica', 8),
(43, 'Erica', 3),
(61, 'Norman', 2),
(30, 'Susan', 8),
(38, 'Denise', 2),
(76, 'Elizabeth', 1),
(34, 'Sandra', 8),
(34, 'Stacey', 2),
(31, 'Angela', 3),
(14, 'John', 5),
(64, 'Aaron', 3),
(63, 'Joseph', 1),
(48, 'Bryan', 6),
(3, 'Jared', 2),
(76, 'Steve', 5),
(36, 'Kelly', 8),
(51, 'Christopher', 0),
(11, 'Michael', 8),
(36, 'Kevin', 0),
(81, 'Leslie', 1),
(26, 'Marc', 5),
(50, 'Glenda', 6),
(53, 'James', 8),
(75, 'Renee', 1),
(82, 'Tyler', 1),
(42, 'Jane', 7),
(8, 'Michael', 5),
(39, 'Michele', 9),
(20, 'Thomas', 0),
(65, 'Regina', 4),
(5, 'Elizabeth', 3),
(43, 'Mallory', 6),
(65, 'David', 5),
(5, 'Carrie', 3),
(65, 'Michael', 5),
(31, 'Alexander', 10),
(24, 'Amanda', 0),
(67, 'Kelly', 0),
(53, 'Jeffrey', 3),
(68, 'Dana', 8),
(70, 'Calvin', 7),
(70, 'Crystal', 4),
(11, 'Erika', 7),
(14, 'Kristin', 9),
(36, 'Cynthia', 7),
(63, 'Raymond', 7),
(28, 'Erica', 3),
(40, 'Samantha', 1),
(27, 'Christopher', 5),
(63, 'Nancy', 2),
(34, 'Raymond', 1),
(20, 'Jacqueline', 1),
(33, 'Eric', 8),
(61, 'Joshua', 1),
(1, 'Denise', 8),
(31, 'Diana', 6),
(44, 'Jennifer', 1),
(54, 'Charles', 7),
(19, 'Paige', 10),
(13, 'Alejandro', 7),
(20, 'James', 3),
(4, 'Daniel', 10),
(75, 'Katherine', 6),
(43, 'Alexander', 0),
(48, 'Karen', 6),
(30, 'Sean', 6),
(43, 'Robert', 1),
(47, 'Angela', 1),
(13, 'Steven', 8),
(24, 'Kyle', 6),
(32, 'Kara', 4),
(78, 'Steven', 4),
(29, 'Michael', 5),
(8, 'Shelley', 7),
(36, 'Sarah', 7),
(46, 'Robert', 10),
(13, 'Meghan', 6),
(63, 'Tony', 2),
(79, 'Tyler', 7),
(43, 'Claudia', 6),
(29, 'Robert', 9),
(50, 'Katherine', 4),
(48, 'Jessica', 8),
(46, 'Nicholas', 8),
(36, 'Audrey', 5),
(63, 'Sara', 8),
(55, 'Erin', 0),
(54, 'John', 0),
(35, 'Jennifer', 7),
(69, 'Nicholas', 0),
(18, 'Antonio', 5),
(76, 'Christina', 9),
(13, 'Justin', 7),
(57, 'Angela', 10),
(59, 'Victoria', 3),
(61, 'Ruben', 1),
(42, 'Edward', 8),
(28, 'Cindy', 3),
(68, 'Victoria', 5),
(55, 'Jon', 0),
(51, 'Victoria', 10),
(27, 'Karen', 0),
(16, 'Sarah', 4),
(72, 'Patricia', 0),
(52, 'Alexis', 4),
(81, 'Diana', 9),
(34, 'Ryan', 1),
(10, 'Kevin', 3),
(22, 'Michael', 3),
(51, 'Andrew', 9),
(1, 'Raymond', 10),
(44, 'Keith', 4),
(55, 'Courtney', 5),
(53, 'Nicholas', 3),
(66, 'Brandon', 10),
(75, 'Keith', 0),
(61, 'Jennifer', 2),
(77, 'John', 3),
(41, 'Alexander', 10),
(31, 'Julia', 8),
(74, 'Sarah', 8),
(68, 'Thomas', 9),
(39, 'Craig', 9),
(20, 'Kevin', 3),
(35, 'Robert', 9),
(41, 'Megan', 4),
(2, 'Nicholas', 8),
(34, 'Lindsey', 6),
(71, 'Kristin', 9),
(72, 'Michael', 4),
(33, 'Kelly', 7),
(47, 'Rebecca', 5),
(50, 'Andrea', 10),
(72, 'Courtney', 0),
(30, 'Robert', 8),
(77, 'Gary', 6),
(41, 'Brandon', 2),
(5, 'Samantha', 1),
(54, 'Danielle', 10),
(41, 'David', 0),
(61, 'Garrett', 9),
(71, 'James', 0),
(52, 'Jose', 1),
(36, 'Michael', 3),
(66, 'Stephen', 4),
(26, 'Rodney', 3),
(27, 'Megan', 0),
(76, 'Danielle', 1),
(23, 'Roger', 6),
(44, 'Teresa', 0),
(37, 'Christopher', 4),
(53, 'Albert', 4),
(42, 'Kelly', 7),
(57, 'Barbara', 7),
(65, 'Robert', 4),
(39, 'Tiffany', 5),
(73, 'Olivia', 0),
(46, 'Natasha', 1),
(1, 'Christopher', 9),
(12, 'James', 5),
(73, 'Mary', 5),
(45, 'Frank', 4),
(32, 'Jessica', 0),
(38, 'Carolyn', 2),
(33, 'Daniel', 8),
(28, 'Christopher', 9),
(71, 'Carlos', 6),
(45, 'Robert', 0),
(26, 'Alexis', 10),
(10, 'John', 7),
(64, 'Johnny', 10),
(31, 'Brittany', 7),
(54, 'Karen', 8),
(47, 'Michelle', 5),
(12, 'Sherry', 6),
(73, 'Beth', 10),
(47, 'Andrew', 10),
(71, 'Chloe', 7),
(71, 'Taylor', 9),
(52, 'Carol', 4),
(63, 'Melissa', 9),
(6, 'David', 5),
(57, 'Michael', 3),
(41, 'Melanie', 10),
(43, 'Bradley', 1),
(79, 'Tim', 8),
(14, 'Brandon', 8),
(30, 'Jennifer', 3),
(76, 'Yolanda', 7),
(3, 'Joshua', 8),
(80, 'Anna', 2),
(79, 'Troy', 8),
(74, 'Stephanie', 4),
(34, 'Ashley', 0),
(36, 'Mark', 8),
(41, 'Dawn', 1),
(49, 'Christian', 4),
(38, 'Autumn', 0),
(61, 'Jeffery', 3),
(38, 'Amber', 4),
(2, 'Mary', 10),
(39, 'Nicholas', 0),
(10, 'Susan', 1),
(71, 'Philip', 0),
(43, 'Sonya', 0),
(27, 'Wendy', 4),
(18, 'Emily', 5),
(37, 'Thomas', 3),
(74, 'Erin', 4),
(74, 'Gregory', 3),
(79, 'Kevin', 0),
(26, 'Richard', 1),
(39, 'Nancy', 8),
(67, 'Cynthia', 8),
(5, 'Lisa', 8),
(44, 'Edgar', 7),
(54, 'Kristin', 9),
(21, 'Melissa', 4),
(45, 'Darrell', 6),
(19, 'Jacob', 7),
(7, 'Veronica', 8),
(51, 'Wesley', 2),
(67, 'Kayla', 0),
(7, 'Marcia', 2),
(35, 'Jacob', 6),
(27, 'Juan', 9),
(77, 'Richard', 10),
(3, 'Emily', 4),
(65, 'Michael', 1),
(22, 'Dorothy', 10),
(39, 'Jason', 8),
(40, 'Joan', 2),
(50, 'Hannah', 0),
(14, 'Paul', 8),
(57, 'Nancy', 7),
(54, 'Stacy', 0),
(29, 'Melissa', 4),
(44, 'Erin', 3),
(64, 'Veronica', 2),
(58, 'Anita', 5),
(51, 'Stephanie', 5),
(38, 'Lisa', 7),
(21, 'Alicia', 5),
(3, 'Caleb', 5),
(43, 'Alicia', 4),
(67, 'Nicholas', 9),
(42, 'Sabrina', 7),
(48, 'Eric', 10),
(35, 'Tony', 1),
(56, 'Tyler', 10),
(27, 'William', 4),
(20, 'Laura', 6),
(45, 'Michael', 7),
(35, 'Troy', 4),
(68, 'Amber', 1),
(54, 'Kristen', 6),
(67, 'John', 8),
(71, 'Michael', 3);

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

INSERT INTO tren_gat (id_gat, id_prac) VALUES
(1, 90),
(2, 16),
(3, 81),
(4, 25),
(5, 79),
(6, 73),
(7, 62),
(8, 66),
(9, 66),
(10, 73),
(11, 79),
(12, 68),
(13, 77),
(14, 58),
(15, 79),
(16, 62),
(17, 20),
(18, 16),
(19, 16),
(20, 73),
(21, 16),
(22, 90),
(23, 58),
(24, 20),
(25, 86),
(26, 20),
(27, 68),
(28, 79),
(29, 25),
(30, 79),
(31, 86),
(32, 75),
(33, 77),
(34, 25),
(35, 75),
(36, 84),
(37, 84),
(38, 11),
(39, 67),
(40, 27),
(41, 51),
(42, 74),
(43, 63),
(44, 75),
(45, 67),
(46, 63),
(47, 67),
(48, 29),
(49, 18),
(50, 18),
(51, 29),
(52, 67),
(53, 96),
(54, 84),
(55, 96),
(56, 33),
(57, 33),
(58, 33),
(59, 33),
(60, 18),
(61, 72),
(62, 72),
(63, 17),
(64, 33),
(65, 51),
(66, 17),
(67, 60),
(68, 42),
(69, 33),
(70, 60),
(71, 42),
(72, 84),
(73, 60),
(74, 33),
(75, 16),
(76, 84),
(77, 77),
(78, 51),
(79, 51),
(80, 51),
(81, 17),
(82, 42);

INSERT INTO opiek_gat (id_prac, id_gat) VALUES
(65, 1),
(43, 2),
(60, 3),
(83, 4),
(60, 5),
(100, 6),
(88, 7),
(59, 8),
(92, 9),
(88, 10),
(60, 11),
(76, 12),
(42, 13),
(76, 14),
(88, 15),
(100, 16),
(31, 17),
(92, 18),
(76, 19),
(43, 20),
(43, 21),
(83, 22),
(92, 23),
(31, 24),
(42, 25),
(83, 26),
(92, 27),
(65, 28),
(42, 29),
(43, 30),
(64, 31),
(92, 32),
(43, 33),
(100, 34),
(96, 35),
(3, 36),
(17, 37),
(57, 38),
(28, 39),
(57, 40),
(3, 41),
(1, 42),
(3, 43),
(28, 44),
(10, 45),
(57, 46),
(95, 47),
(96, 48),
(10, 49),
(17, 50),
(28, 51),
(57, 52),
(10, 53),
(79, 54),
(96, 55),
(95, 56),
(79, 57),
(78, 58),
(95, 59),
(15, 60),
(95, 61),
(57, 62),
(78, 63),
(1, 64),
(78, 65),
(15, 66),
(1, 67),
(15, 68),
(78, 69),
(1, 70),
(47, 71),
(78, 72),
(1, 73),
(50, 74),
(46, 75),
(1, 76),
(46, 77),
(29, 78),
(62, 79),
(50, 80),
(62, 81),
(29, 82);

INSERT INTO sprzat_wybieg (id_prac, id_wybieg) VALUES
(79, 1), (65, 2), (90, 3), (56, 4), (37, 5), (69, 6), (16, 7), (51, 8), (7, 9), (38, 10),
(44, 11), (43, 12), (81, 13), (32, 14), (21, 15), (25, 16), (88, 17), (23, 18), (82, 19), (73, 20),
(34, 21), (62, 22), (52, 23), (66, 24), (50, 25), (24, 26), (68, 27), (49, 28), (86, 29), (89, 30),
(98, 31), (77, 32), (99, 33), (40, 34), (60, 35), (94, 36), (83, 37), (92, 38), (64, 39), (36, 40),
(76, 41), (22, 42), (100, 43), (91, 44), (93, 45), (71, 46), (58, 47), (6, 48), (42, 49), (20, 50),
(75, 51), (84, 52), (33, 53), (31, 54), (11, 55), (87, 56), (80, 57), (30, 58), (8, 59), (96, 60),
(9, 61), (35, 62), (72, 63), (19, 64), (27, 65), (97, 66), (3, 67), (26, 68), (17, 69), (10, 70),
(55, 71), (18, 72), (67, 73), (74, 74), (48, 75), (57, 76), (28, 77), (59, 78), (63, 79), (95, 80),
(12, 1), (2, 2), (1, 3), (70, 4), (61, 5), (85, 6), (5, 7), (78, 8), (14, 9), (29, 10),
(45, 11), (15, 12), (47, 13), (54, 14), (4, 15), (41, 16), (53, 17), (46, 18), (39, 19), (13, 20),
(91, 1), (50, 2), (29, 3), (84, 4), (86, 5), (75, 6), (96, 7), (60, 8), (79, 9), (51, 10),
(47, 11), (73, 12), (57, 13), (83, 14), (66, 15), (26, 16), (34, 17), (17, 18), (62, 19), (64, 20),
(46, 21), (31, 22), (42, 23), (59, 24);

INSERT INTO popisy (trener, gatunek, min_ilosc, min_poz) VALUES
(52, 40, 3, 6),
(96, 26, 2, 7),
(33, 61, 4, 8),
(64, 16, 5, 2),
(69, 53, 6, 5),
(59, 17, 6, 9),
(96, 68, 1, 2),
(62, 9, 4, 7),
(50, 46, 6, 6),
(27, 20, 5, 7),
(31, 33, 4, 1),
(26, 62, 7, 1),
(85, 40, 1, 3),
(92, 47, 8, 3),
(65, 52, 6, 1),
(87, 22, 2, 6),
(42, 46, 6, 8),
(97, 27, 8, 9),
(78, 29, 8, 9),
(97, 46, 9, 7),
(14, 40, 4, 10),
(90, 7, 6, 0),
(74, 26, 8, 6),
(79, 6, 3, 2),
(1, 67, 2, 0),
(88, 15, 5, 1),
(1, 28, 7, 2),
(29, 60, 6, 0),
(52, 63, 8, 0),
(6, 67, 3, 10),
(21, 49, 1, 8),
(87, 51, 2, 4),
(35, 47, 5, 4),
(100, 11, 8, 5),
(89, 56, 2, 6),
(40, 17, 7, 2),
(47, 72, 6, 4),
(28, 62, 7, 2),
(30, 28, 3, 4),
(12, 50, 7, 5),
(32, 2, 6, 3),
(4, 71, 7, 8),
(18, 71, 6, 1),
(23, 15, 3, 0),
(55, 76, 7, 0),
(89, 33, 7, 0),
(28, 60, 4, 3),
(21, 72, 3, 8),
(57, 66, 9, 3),
(93, 26, 3, 10),
(1, 22, 9, 2),
(74, 36, 3, 10),
(40, 65, 4, 8),
(11, 29, 8, 2),
(55, 58, 1, 1),
(79, 82, 1, 6),
(48, 19, 2, 1),
(1, 19, 1, 5),
(55, 45, 8, 0),
(1, 5, 9, 3),
(12, 30, 2, 8),
(100, 63, 8, 8),
(11, 52, 6, 4),
(6, 45, 2, 6),
(18, 53, 1, 6),
(27, 48, 8, 1),
(49, 38, 3, 9),
(91, 71, 1, 7),
(100, 74, 5, 7),
(100, 37, 8, 6),
(24, 74, 5, 10),
(12, 75, 7, 1),
(11, 37, 2, 7),
(65, 63, 2, 10),
(75, 71, 9, 10),
(18, 43, 5, 9),
(1, 50, 2, 10),
(27, 31, 2, 7),
(40, 11, 9, 9),
(38, 18, 1, 1),
(21, 20, 9, 10),
(84, 57, 9, 8),
(4, 55, 7, 7),
(93, 62, 8, 10),
(16, 26, 8, 2),
(56, 45, 6, 9),
(25, 32, 8, 3),
(48, 7, 8, 8),
(30, 55, 7, 0),
(43, 66, 6, 7),
(9, 25, 4, 7),
(94, 75, 7, 6),
(66, 11, 9, 6),
(59, 17, 5, 0),
(53, 81, 8, 6),
(68, 20, 3, 1),
(57, 55, 2, 3),
(20, 9, 4, 5),
(75, 56, 1, 5);
