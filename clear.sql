-- tabele

-- Drop triggers
DROP TRIGGER IF EXISTS dobry_pesel ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS akt_popisow ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS aktualizacja_godziny_otwarcia ON godziny_otwarcia CASCADE;
DROP TRIGGER IF EXISTS check_plan_dnia ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS check_popisy ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS historia_zwierzat_trigger ON zwierzeta CASCADE;
DROP TRIGGER IF EXISTS historia_gatunkow_trigger ON gatunki CASCADE;
DROP TRIGGER IF EXISTS historia_wybiegow_trigger ON wybiegi CASCADE;
DROP TRIGGER IF EXISTS czy_ma_stanowisko ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS gatunki_opiekun ON gatunki CASCADE;
DROP TRIGGER IF EXISTS opiekun_gatunki ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS wybiegi_cleaner_trigger ON wybiegi CASCADE;
DROP TRIGGER IF EXISTS historia_planu ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS check_popisy ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS cascade_delete_pracownicy_trigger ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS cascade_delete_gatunki_trigger ON gatunki CASCADE;

-- Drop functions
DROP FUNCTION IF EXISTS dobry_pesel CASCADE;
DROP FUNCTION IF EXISTS check_godziny_otwarcia CASCADE;
DROP FUNCTION IF EXISTS check_godzina_popisow CASCADE;
DROP FUNCTION IF EXISTS historia_planu CASCADE;
DROP FUNCTION IF EXISTS check_plan_dnia CASCADE;
DROP FUNCTION IF EXISTS check_popisy CASCADE;
DROP FUNCTION IF EXISTS cascade_delete_pracownicy CASCADE;
DROP FUNCTION IF EXISTS cascade_delete_gatunki CASCADE;
DROP FUNCTION IF EXISTS dodaj_do_historii_zwierzat CASCADE;
DROP FUNCTION IF EXISTS dodaj_do_historii_gatunkow CASCADE;
DROP FUNCTION IF EXISTS dodaj_do_historii_wybiegow CASCADE;
DROP FUNCTION IF EXISTS check_stanowisko CASCADE;
DROP FUNCTION IF EXISTS check_opiekun CASCADE;
DROP FUNCTION IF EXISTS check_gatunki CASCADE;
DROP FUNCTION IF EXISTS check_sprzatacz CASCADE;

-- Drop views
DROP VIEW IF EXISTS plan_24h CASCADE;
DROP VIEW IF EXISTS plan_godziny_otwarcia CASCADE;

-- Drop tables
DROP TABLE IF EXISTS godziny_otwarcia CASCADE;
DROP TABLE IF EXISTS historia_godziny_otwarcia CASCADE;
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
DROP TABLE IF EXISTS historia_zwierzat CASCADE;
DROP TABLE IF EXISTS historia_pracownicy_godziny_pracy CASCADE;
DROP TABLE IF EXISTS historia_opiekunowie_gatunki CASCADE;
DROP TABLE IF EXISTS historia_gatunkow CASCADE;
DROP TABLE IF EXISTS historia_wybiegow CASCADE;

DROP VIEW IF EXISTS plan_24h CASCADE;
DROP VIEW IF EXISTS plan_godziny_otwarcia CASCADE;


-- funkcje trigger

DROP TRIGGER IF EXISTS hash_password ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS dobry_pesel ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS akt_popisow ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS aktualizacja_godziny_otwarcia ON godziny_otwarcia CASCADE;
DROP TRIGGER IF EXISTS check_plan_dnia ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS check_popisy ON plan_dnia CASCADE;
DROP TRIGGER IF EXISTS cascade_delete_pracownicy_trigger ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS cascade_delete_gatunki_trigger ON gatunki CASCADE;
DROP TRIGGER IF EXISTS historia_zwierzat_trigger ON zwierzeta CASCADE;
DROP TRIGGER IF EXISTS historia_gatunkow_trigger ON gatunki CASCADE;
DROP TRIGGER IF EXISTS historia_wybiegow_trigger ON wybiegi CASCADE;
DROP TRIGGER IF EXISTS czy_ma_stanowisko ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS gatunki_opiekun ON gatunki CASCADE;
DROP TRIGGER IF EXISTS opiekun_gatunki ON pracownicy CASCADE;
DROP TRIGGER IF EXISTS wybiegi_cleaner_trigger ON wybiegi CASCADE;


DROP FUNCTION IF EXISTS jeden CASCADE;
DROP FUNCTION IF EXISTS check_godzina_popisow CASCADE;
DROP FUNCTION IF EXISTS update_licznosc_gatunku CASCADE;
DROP FUNCTION IF EXISTS check_godz_otwarcia CASCADE;
DROP FUNCTION IF EXISTS check_plan_dnia CASCADE;
DROP FUNCTION IF EXISTS check_popisy CASCADE;
DROP FUNCTION IF EXISTS dobry_pesel CASCADE;
DROP FUNCTION IF EXISTS check_godziny_otwarcia CASCADE;
DROP FUNCTION IF EXISTS check_godzina_popisow CASCADE;
DROP FUNCTION IF EXISTS historia_planu CASCADE;
DROP FUNCTION IF EXISTS check_plan_dnia CASCADE;
DROP FUNCTION IF EXISTS check_popisy CASCADE;
DROP FUNCTION IF EXISTS cascade_delete_pracownicy CASCADE;
DROP FUNCTION IF EXISTS cascade_delete_gatunki CASCADE;
DROP FUNCTION IF EXISTS dodaj_do_historii_zwierzat CASCADE;
DROP FUNCTION IF EXISTS dodaj_do_historii_gatunkow CASCADE;
DROP FUNCTION IF EXISTS dodaj_do_historii_wybiegow CASCADE;
DROP FUNCTION IF EXISTS check_stanowisko CASCADE;
DROP FUNCTION IF EXISTS check_opiekun CASCADE;
DROP FUNCTION IF EXISTS check_gatunki CASCADE;
DROP FUNCTION IF EXISTS check_sprzatacz CASCADE;

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
