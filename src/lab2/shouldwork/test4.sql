


--Testing trigger person_update & func update_person() -- klar (town = no visitbonus only roadtax)
--SETUP
INSERT  INTO  Countries  VALUES(' ');
INSERT  INTO  Countries  VALUES('Swe');
INSERT  INTO  Areas  VALUES( 'Swe', 'Gbg',491630);
INSERT  INTO  Persons  VALUES(' ', ' ', 'The government', 'Swe', 'Gbg', 100000000000);
INSERT INTO Cities VALUES( 'Swe','Gbg',0);
INSERT  INTO  Countries  VALUES('Irl');
INSERT  INTO  Areas  VALUES( 'Irl','Dub', 491630);
INSERT INTO Cities VALUES( 'Irl','Dub',0);
INSERT  INTO  Areas  VALUES( 'Irl', 'Gal',33529);
INSERT INTO Towns VALUES( 'Irl','Gal');
INSERT INTO ROADS
VALUES('Irl',
       'Dub',
       'Irl',
       'Gal',
       ' ',
       ' ');
--END SETUP
INSERT INTO Persons VALUES ('Swe', '19940202-4817', 'Allans klon 2', 'Irl', 'Dub', 1000000);
UPDATE Persons SET locationarea = 'Gal'
WHERE country = 'Swe' AND personnummer = '19940202-4817';
