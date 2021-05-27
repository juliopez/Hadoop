CREATE DATABASE IF NOT EXISTS hue;
grant all on hue.* to 'hue'@'172.27.1.13' identified by 'secretpassword';
grant all on hue.* to 'root'@'172.27.1.13' identified by 'secret';
flush privileges; 
use hue;
