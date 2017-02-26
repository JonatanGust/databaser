
--Testing trigger person_update & func update_person() -- klart! ( roadtax i visit bonus 0 hotels)
--SETUP
INSERT  INTO  Countries  VALUES(' ');
INSERT  INTO  Countries  VALUES('Swe');
INSERT  INTO  Areas  VALUES( 'Swe', 'Gbg',491630);
INSERT  INTO  Persons  VALUES(' ', ' ', 'The government', 'Swe', 'Gbg', 100000000000);
INSERT  INTO  Countries  VALUES('Irl');
INSERT  INTO  Areas  VALUES( 'Irl','Ath', 491630);
INSERT INTO Cities VALUES( 'Irl','Ath',0);
INSERT  INTO  Areas  VALUES( 'Irl','Lim', 33529);
INSERT INTO Cities VALUES( 'Irl','Lim',13.5);
INSERT INTO ROADS
VALUES('Irl',
       'Ath',
       'Irl',
       'Lim',
       ' ',
       ' ');
--END SETUP
INSERT INTO Persons VALUES ('Swe', '19940202-4818', 'Allans klon 3', 'Irl', 'Ath', 1000000);
UPDATE Persons SET locationarea = 'Lim'
WHERE country = 'Swe' AND personnummer = '19940202-4818';
