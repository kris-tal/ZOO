-- tabele

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
DROP TABLE IF EXISTS historia_wybiegow CASCADE;
DROP TABLE IF EXISTS historia_zwierzat CASCADE;
DROP TABLE IF EXISTS historia_pracownikow CASCADE;

DROP VIEW IF EXISTS plan_24h CASCADE;
DROP VIEW IF EXISTS plan_godziny_otwarcia CASCADE;


-- funkcje trigger

DROP TRIGGER IF EXISTS pojedynczy_wiersz ON godziny_otwarcia CASCADE;
DROP TRIGGER IF EXISTS aktualizacja_godziny_otwarcia ON godziny_otwarcia CASCADE;
DROP TRIGGER IF EXISTS change_zwierzeta ON zwierzeta CASCADE;
DROP TRIGGER IF EXISTS dobry_pesel ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS akt_popisow ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS check_plan_dnia ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS check_popisy ON plan_dnia CASCADE;


DROP FUNCTION IF EXISTS jeden CASCADE;
DROP FUNCTION IF EXISTS check_godzina_popisow CASCADE;
DROP FUNCTION IF EXISTS update_licznosc_gatunku CASCADE;
DROP FUNCTION IF EXISTS check_godz_otwarcia CASCADE;
DROP FUNCTION IF EXISTS check_plan_dnia CASCADE;
DROP FUNCTION IF EXISTS check_popisy CASCADE;

-- zwykle funkcje

DROP FUNCTION IF EXISTS dobry_pesel CASCADE;


-- sekwencje

DROP SEQUENCE IF EXISTS zwierzeta_id_seq CASCADE;
DROP SEQUENCE IF EXISTS wybiegi_id_seq CASCADE;
DROP SEQUENCE IF EXISTS strefy_id_seq CASCADE;
DROP SEQUENCE IF EXISTS stanowiska_id_seq CASCADE;
DROP SEQUENCE IF EXISTS pracownicy_id_seq CASCADE;
DROP SEQUENCE IF EXISTS popisy_id_seq CASCADE;
DROP SEQUENCE IF EXISTS plan_dnia_id_seq CASCADE;
DROP SEQUENCE IF EXISTS niedyspozycja_zwierzat_id_seq CASCADE;
DROP SEQUENCE IF EXISTS nieobecnosci_pracownikow_id_seq CASCADE;
DROP SEQUENCE IF EXISTS gatunki_id_seq CASCADE;
