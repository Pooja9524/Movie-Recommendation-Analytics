CREATE DATABASE MovieRec ;
USE MovieRec;

drop table Film_Det;

create table Genre(
Gen_Id INT Primary Key Auto_Increment,
Gen_Name VARCHAR(100) unique not null
);

DESC Genre;

create table Film_Det(
Mov_id int PRIMARY KEY AUTO_INCREMENT,
Title varchar(200) not null,
Gen_Id INT NOT NULL,
FOREIGN KEY (Gen_Id) REFERENCES Genre(Gen_Id),
Rel_Year year not null,
Duration INT not null
);

DESC Film_Det;

create table Film_Lang(
Mov_id INT NOT NULL, FOREIGN KEY (Mov_Id) REFERENCES Film_Det(Mov_Id),
Film_Lang Varchar(100) not NULL,
UNIQUE (Mov_id,Film_Lang)
);

create table Users(
User_id INT PRIMARY KEY AUTO_INCREMENT,
UserName Varchar(100) Not NUll unique,
Email varchar(150) not null unique,
Age Int not null,
Country varchar(60),
Join_date date not null
);

create table watch_history(

);