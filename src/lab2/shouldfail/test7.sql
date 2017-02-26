
-- Test of Hotel Insert that person does'nt have enough money -- KLAR!!

INSERT INTO Countries
VALUES('Nor');

INSERT INTO Areas
VALUES('Nor','Osl',3000000);
INSERT INTO Cities
VALUES('Nor','Osl',0);

INSERT INTO Areas
VALUES('Nor','Bergen',3000000);
INSERT INTO Cities
VALUES('Nor','Bergen',0);

INSERT INTO Persons
VALUES('Nor',
       '19960708-3664',
       'Theodor Clone',
       'Nor',
       'Osl',
       1 );

INSERT INTO Hotels
VALUES('Hotel in Oslo',
      'Nor',
      'Bergen',
      'Nor',
      '19960708-3664')
