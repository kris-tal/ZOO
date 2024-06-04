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

-- CREATE OR REPLACE FUNCTION check_sprzatacz() RETURNS TRIGGER AS $$
-- BEGIN
--     IF NEW.nazwa = 'sprzatacz' AND NOT EXISTS (SELECT 1 FROM sprzatacze_wybiegi WHERE id_pracownika = NEW.id_pracownika) THEN
--         RAISE EXCEPTION 'kazdy sprzatacz musi miec wybieg';
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- CREATE CONSTRAINT TRIGGER cleaner_enclosure_trigger
-- AFTER INSERT OR UPDATE ON pracownicy_stanowiska
-- DEFERRABLE INITIALLY DEFERRED
-- FOR EACH ROW EXECUTE PROCEDURE check_cleaner_enclosure();

-- CREATE OR REPLACE FUNCTION check_trener_gatunek() RETURNS TRIGGER AS $$
-- BEGIN
--     IF NEW.id_stanowiska = 3 AND NOT EXISTS (SELECT 1 FROM trenerzy_gatunki WHERE id_pracownika = NEW.id_pracownika) THEN
--         RAISE EXCEPTION 'kazdy trener musi miec gatunek';
--     END IF;
--     RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;
--
-- CREATE CONSTRAINT TRIGGER trener_gatunek
-- AFTER INSERT OR UPDATE ON pracownicy_stanowiska
-- DEFERRABLE INITIALLY DEFERRED
-- FOR EACH ROW EXECUTE PROCEDURE check_trener_gatunek();