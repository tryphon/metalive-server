create table events (
  id INT NOT NULL AUTO_INCREMENT,
  occurred_at DATETIME,
  description TEXT,
  uuid VARCHAR(255),
  PRIMARY KEY (id)
);
