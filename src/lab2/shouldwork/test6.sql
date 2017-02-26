
--Testing trigger hotel_delete & func hotel_sold -- klar
    --SETUP
INSERT  INTO  Countries  VALUES(' ');
INSERT  INTO  Countries  VALUES('Swe');
INSERT  INTO  Areas  VALUES( 'Swe', 'Gbg',491630);
INSERT  INTO  Persons  VALUES(' ', ' ', 'The government', 'Swe', 'Gbg', 100000000000);
INSERT INTO Cities VALUES( 'Swe','Gbg',0);
INSERT  INTO  Areas  VALUES( 'Swe', 'Sth',491630*2);
INSERT INTO Cities VALUES( 'Swe','Sth',0);
    --END SETUP
INSERT INTO Persons VALUES ('Swe', '19940202-4816', 'Allans klon', 'Swe', 'Gbg', 1000000);
INSERT INTO Hotels VALUES('Hotel GBG', 'Swe', 'Gbg', 'Swe', '19940202-4816');
DELETE FROM Hotels WHERE ownercountry = 'Swe' AND ownerpersonnummer = '19940202-4816' AND locationcountry = 'Swe' AND locationname = 'Gbg';
--assert( SELECT budget FROM Persons WHERE country = 'Swe' AND personnummer = '19940202-4816' , 1000000 - getval('hotelprice') + (getval('hotelprice')*getval('hotelrefund'));
