% Population study
close all
clear
clc
%%
t = readtable("pop.csv");
n = 2022 - t.birth_year;

media = mean(n)
sd = std(n)
min(n)
max(n)
