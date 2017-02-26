
-- Test of Hotel Update where only the owner of an hotel can be changed-- KLAR!!

INSERT INTO Countries
VALUES('Fin');

INSERT INTO Areas
VALUES('Fin','Hel',2000000);
INSERT INTO Cities
VALUES('Fin','Hel',0);

INSERT INTO Areas
VALUES('Fin','Esbo',2000000);
INSERT INTO Cities
VALUES('Fin','Esbo',0);

INSERT INTO Persons
VALUES('Fin',
       '19960708-2664',
       'Theodor Sturesson clone',
       'Fin',
       'Hel',
       150000 );

INSERT INTO Hotels
VALUES('Hotel in Finland',
      'Fin',
      'Hel',
      'Fin',
      '19960708-2664');

UPDATE Hotels SET locationcountry = 'Fin', locationname = 'Esbo'
WHERE ( locationcountry = 'Fin'
    AND locationname = 'Hel'
    AND ownercountry = 'Fin'
    AND ownerpersonnummer = '19960708-2664');
