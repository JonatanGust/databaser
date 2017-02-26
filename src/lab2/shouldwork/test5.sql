
--Testing trigger hotel_insert -- klar
    --SETUP
INSERT  INTO  Countries  VALUES(' ');
INSERT  INTO  Countries  VALUES('Swe');
INSERT  INTO  Areas  VALUES( 'Swe', 'Gbg',491630);
INSERT  INTO  Persons  VALUES(' ', ' ', 'The government', 'Swe', 'Gbg', 100000000000);
INSERT INTO Cities VALUES( 'Swe','Gbg',0);
INSERT  INTO  Areas  VALUES( 'Swe', 'Sth',4916302);
INSERT INTO Cities VALUES( 'Swe','Sth',0);
INSERT INTO Persons VALUES ('Swe', '19940202-4817', 'Allans klon 2', 'Swe', 'Gbg', 1000000);
    --END SETUP
INSERT INTO Hotels VALUES('Hotel GBG', 'Swe', 'Gbg', 'Swe', '19940202-4817');
--assert( SELECT budget FROM Persons WHERE country = 'Swe' AND personnummer = '19940202-4816' , 1000000 - getval('hotelprice') );
