CREATE TABLE historia_wybiegow AS SELECT *, NULL::date as data_usuniecia FROM wybiegi;
ALTER TABLE historia_wybiegow ADD PRIMARY KEY (id, data_usuniecia);

CREATE TABLE historia_gatunkow AS SELECT *, NULL::date as data_usuniecia FROM gatunki;
ALTER TABLE historia_gatunkow ADD PRIMARY KEY (id, data_usuniecia);

CREATE TABLE historia_zwierzat AS SELECT *, NULL::date as data_usuniecia FROM zwierzeta;
ALTER TABLE historia_zwierzat ADD PRIMARY KEY (id, data_usuniecia);

CREATE TABLE historia_pracownikow AS SELECT *, NULL::date as data_usuniecia FROM pracownicy;
ALTER TABLE historia_pracownikow ADD PRIMARY KEY (id, data_usuniecia);


--jeszce bedzie historia