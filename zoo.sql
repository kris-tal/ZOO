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
    zamkniecie TIME NOT NULL
);

CREATE TABLE pracownicy (
    id SERIAL PRIMARY KEY ,
    imie VARCHAR(40) NOT NULL ,
    nazwisko VARCHAR(40) NOT NULL ,
    pesel CHAR(11), --CHECK(dobry_pesel(pesel)) ,
    godz_od TIME DEFAULT '8:00'::time NOT NULL ,        --nie ograniczamy godzin pracy bo mozna pracowac w nocy
    godz_do TIME DEFAULT '15:00'::time NOT NULL
);
INSERT INTO pracownicy (id, imie, nazwisko, pesel, godz_od, godz_do) VALUES
(1, 'Józef', 'Sanetra', '85090127679', '03:31:33'::time, '10:10:25'::time),
(2, 'Blanka', 'Kijas', '25011909517', '03:43:06'::time, '11:47:56'::time),
(3, 'Dagmara', 'Wolff', '03073139598', '11:11:54'::time, '18:56:57'::time),
(4, 'Elżbieta', 'Kuszyk', '20040926328', '13:02:21'::time, '19:41:29'::time),
(5, 'Anastazja', 'Kozon', '76042421194', '08:43:20'::time, '15:08:13'::time),
(6, 'Alex', 'Schubert', '14121654439', '03:58:29'::time, '13:29:01'::time),
(7, 'Maurycy', 'Szkaradek', '82112627751', '11:32:41'::time, '21:41:36'::time),
(8, 'Tobiasz', 'Wota', '62120872392', '08:52:52'::time, '17:51:12'::time),
(9, 'Ksawery', 'Tórz', '66050173897', '02:44:45'::time, '12:06:22'::time),
(10, 'Sandra', 'Pilarek', '29092312288', '02:19:52'::time, '08:06:37'::time),
(11, 'Aleks', 'Szram', '56033139231', '09:07:21'::time, '19:41:05'::time),
(12, 'Arkadiusz', 'Drygała', '18020918285', '07:01:22'::time, '13:42:08'::time),
(13, 'Marianna', 'Wojtczuk', '90030960159', '09:36:51'::time, '17:43:07'::time),
(14, 'Krystian', 'Tarasek', '09030433013', '01:35:03'::time, '09:49:38'::time),
(15, 'Ewelina', 'Nagel', '66012029758', '11:40:03'::time, '17:07:56'::time),
(16, 'Agnieszka', 'Huber', '83060308367', '09:59:22'::time, '19:03:24'::time),
(17, 'Gustaw', 'Policht', '88060750510', '09:30:09'::time, '19:54:55'::time),
(18, 'Ignacy', 'Władyka', '23012955612', '03:28:35'::time, '10:28:17'::time),
(19, 'Konstanty', 'Kolanko', '01041115289', '00:59:20'::time, '10:04:02'::time),
(20, 'Juliusz', 'Rećko', '64011456766', '01:30:22'::time, '09:53:54'::time),
(21, 'Grzegorz', 'Pietrasz', '61051369423', '05:33:17'::time, '15:03:59'::time),
(22, 'Dominik', 'Burchardt', '71051893086', '08:35:22'::time, '15:28:12'::time),
(23, 'Jan', 'Zyzik', '38030224017', '09:21:34'::time, '17:34:03'::time),
(24, 'Roksana', 'Kiszczak', '59010475362', '06:15:48'::time, '14:50:55'::time),
(25, 'Bruno', 'Prawdzik', '64052678679', '07:45:04'::time, '17:27:16'::time),
(26, 'Marcelina', 'Dub', '14021291543', '05:38:08'::time, '12:27:24'::time),
(27, 'Ewelina', 'Durlik', '11081347072', '02:03:08'::time, '10:38:44'::time),
(28, 'Kazimierz', 'Okła', '29120886477', '02:46:09'::time, '09:50:35'::time),
(29, 'Krystyna', 'Kazubek', '23060525919', '11:13:59'::time, '19:34:56'::time),
(30, 'Albert', 'Buszko', '68110981330', '03:49:30'::time, '09:06:25'::time),
(31, 'Paweł', 'Juszczuk', '99062212946', '13:57:03'::time, '19:16:32'::time),
(32, 'Alex', 'Dziewior', '31070395295', '10:32:24'::time, '16:44:50'::time),
(33, 'Julian', 'Strzała', '97012059553', '08:23:25'::time, '17:24:40'::time),
(34, 'Krzysztof', 'Palej', '84052251058', '00:17:06'::time, '08:11:51'::time),
(35, 'Marika', 'Księżak', '07092484026', '10:29:41'::time, '20:20:46'::time),
(36, 'Malwina', 'Dub', '15102040441', '10:18:35'::time, '18:29:57'::time),
(37, 'Anna Maria', 'Rabiej', '48041453353', '12:28:43'::time, '22:10:44'::time),
(38, 'Hubert', 'Gołofit', '22100365177', '11:14:05'::time, '21:01:20'::time),
(39, 'Albert', 'Serwach', '54012288985', '06:21:38'::time, '13:12:07'::time),
(40, 'Ryszard', 'Ubysz', '07071029277', '12:58:02'::time, '18:40:15'::time),
(41, 'Michał', 'Mydlarz', '65113092320', '10:29:58'::time, '17:02:04'::time),
(42, 'Angelika', 'Godzwon', '07021331865', '00:11:08'::time, '07:19:59'::time),
(43, 'Błażej', 'Nazarewicz', '55070526349', '10:47:20'::time, '18:18:38'::time),
(44, 'Józef', 'Gasek', '30030146388', '10:05:12'::time, '19:41:10'::time),
(45, 'Marianna', 'Cich', '56121636084', '01:31:33'::time, '11:50:26'::time),
(46, 'Aniela', 'Lepak', '89022662427', '07:48:51'::time, '15:43:36'::time),
(47, 'Liwia', 'Chalimoniuk', '21112700174', '13:37:37'::time, '22:28:34'::time),
(48, 'Ernest', 'Rezmer', '01102702887', '13:30:18'::time, '23:31:24'::time),
(49, 'Hubert', 'Filiks', '39013036751', '01:02:28'::time, '07:17:00'::time),
(50, 'Sylwia', 'Dybiec', '72040476495', '10:06:19'::time, '19:43:38'::time),
(51, 'Nikodem', 'Niedźwiadek', '81042846098', '09:30:02'::time, '18:10:58'::time),
(52, 'Justyna', 'Bieszke', '21120843070', '02:03:38'::time, '08:39:37'::time),
(53, 'Aleks', 'Granat', '18101235746', '11:57:32'::time, '20:35:06'::time),
(54, 'Aurelia', 'Smektała', '52032576606', '08:12:53'::time, '15:15:21'::time),
(55, 'Aniela', 'Wyskiel', '11062822509', '04:03:03'::time, '12:51:55'::time),
(56, 'Marek', 'Mirończuk', '17062497141', '02:20:46'::time, '08:36:31'::time),
(57, 'Marek', 'Wałaszek', '79012474305', '13:53:12'::time, '20:35:30'::time),
(58, 'Kazimierz', 'Stebel', '08032056466', '13:48:45'::time, '22:37:41'::time),
(59, 'Filip', 'Kołaczyk', '13030386196', '01:06:10'::time, '07:29:18'::time),
(60, 'Angelika', 'Kulus', '91121205964', '07:08:25'::time, '17:19:54'::time),
(61, 'Lidia', 'Golczyk', '50060567285', '10:30:13'::time, '17:51:04'::time),
(62, 'Aleksander', 'Dzieża', '99120178012', '10:58:40'::time, '19:13:25'::time),
(63, 'Kajetan', 'Dobrosz', '12011520080', '05:41:30'::time, '14:38:25'::time),
(64, 'Mikołaj', 'Pyrkosz', '75022181567', '04:10:14'::time, '12:07:54'::time),
(65, 'Karol', 'Cieciora', '65021926845', '02:26:41'::time, '12:42:42'::time),
(66, 'Alan', 'Budych', '42022002392', '03:07:31'::time, '09:07:13'::time),
(67, 'Wojciech', 'Glegoła', '03061707705', '01:27:04'::time, '07:53:06'::time),
(68, 'Julita', 'Prażuch', '45041055264', '09:03:54'::time, '18:12:43'::time),
(69, 'Nela', 'Kultys', '68020211840', '05:22:08'::time, '11:32:05'::time),
(70, 'Aleksander', 'Poreda', '28112702793', '13:31:15'::time, '22:31:21'::time),
(71, 'Sandra', 'Biernacik', '14051589351', '07:29:42'::time, '15:53:35'::time),
(72, 'Blanka', 'Rusnak', '20033170433', '08:30:16'::time, '18:46:22'::time),
(73, 'Marcelina', 'Tonder', '74010391155', '01:10:18'::time, '08:28:56'::time),
(74, 'Krzysztof', 'Dycha', '24092125018', '08:28:47'::time, '17:14:29'::time),
(75, 'Elżbieta', 'Koźlak', '49122042945', '04:49:36'::time, '12:59:44'::time),
(76,'Agnieszka', 'Porzucek', '87051373475', '12:32:53'::time, '21:41:21'::time),
(77,'Ryszard', 'Żołądź', '59050212194', '02:20:58'::time, '09:36:05'::time),
(78,'Andrzej', 'Jędral', '22030968059', '08:59:01'::time, '15:15:30'::time),
(79,'Artur', 'Chaba', '00052118445', '04:21:33'::time, '14:10:00'::time),
(80,'Kornelia', 'Szuta', '72082279588', '03:17:02'::time, '09:01:32'::time),
(81,'Albert', 'Roter', '72080465938', '09:16:23'::time, '17:13:54'::time),
(82,'Ewa', 'Frydrychowicz', '57041458183', '11:42:24'::time, '17:33:02'::time),
(83,'Natasza', 'Dzienis', '96041138796', '11:45:43'::time, '21:28:02'::time),
(84,'Julianna', 'Cieciora', '47070518039', '07:54:48'::time, '13:31:07'::time),
(85,'Jan', 'Jenek', '66080207739', '06:14:00'::time, '13:02:56'::time),
(86,'Oskar', 'Pyda', '36071297645', '11:30:02'::time, '17:06:03'::time),
(87,'Kornelia', 'Wośko', '34031812374', '05:53:32'::time, '15:49:53'::time),
(88,'Cyprian', 'Ernst', '40071564603', '06:23:34'::time, '14:50:13'::time),
(89,'Urszula', 'Giec', '29082928813', '04:19:23'::time, '12:21:01'::time),
(90,'Piotr', 'Siergiej', '58092691992', '02:43:22'::time, '10:47:04'::time),
(91,'Fryderyk', 'Hanc', '14090335094', '04:39:02'::time, '14:23:15'::time),
(92,'Piotr', 'Godyń', '96010650933', '07:19:58'::time, '14:51:16'::time),
(93,'Kazimierz', 'Durlej', '12052944791', '13:01:17'::time, '21:24:59'::time),
(94,'Wojciech', 'Balas', '07010877165', '02:30:03'::time, '09:16:18'::time),
(95,'Nela', 'Dudczak', '82072026447', '05:15:19'::time, '14:39:57'::time),
(96,'Rozalia', 'Kapałka', '03042945201', '04:26:17'::time, '14:47:12'::time),
(97,'Anastazja', 'Truchel', '03050925147', '03:58:50'::time, '12:12:44'::time),
(98,'Natasza', 'Kożuszek', '79041885011', '02:00:17'::time, '11:55:12'::time),
(99,'Kornel', 'Hamera', '82081887185', '10:10:56'::time, '18:09:34'::time),
(100,'Janina', 'Fiołka', '37070524008', '01:39:30'::time, '08:27:28'::time);


CREATE TABLE konta (
    id_prac INTEGER PRIMARY KEY REFERENCES pracownicy(id) NOT NULL ,
    haslo INTEGER --to bedzie hash hasla ale hashowanie juz chyba nie w psql
);

CREATE TABLE stanowisko (
    id SERIAL PRIMARY KEY ,
    nazwa CHAR(20) CHECK(nazwa = 'zarzadca' OR nazwa = 'sprzatacz' OR nazwa = 'trener' OR nazwa = 'opiekun') NOT NULL
);
INSERT INTO stanowisko (nazwa) VALUES ('zarzadca');
INSERT INTO stanowisko (nazwa) VALUES ('sprzatacz');
INSERT INTO stanowisko (nazwa) VALUES ('trener');
INSERT INTO stanowisko (nazwa) VALUES ('opiekun');

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