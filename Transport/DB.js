"use strict";

var DBConnection = function(version) {
    this.name = "transport-basic";
    this.version = version || "0.1";
    this.fullName = "CZ+SK-transport-app";
    this.size = 100000;

    console.log("DB version: " + this.version);

    this.db = null;
    this.open();
}

DBConnection.prototype.open = function() {
    if(this.db === null) {
        try {
            var self = this;
            this.db = Sql.LocalStorage.openDatabaseSync(this.name, "", this.fullName, this.size);

            if(this.db) {
                if(!this.db.version || this.db.version !== this.version) {
                    console.log("Changing DB version:", this.db.version, this.version);
                    this.db.changeVersion(this.db.version, this.version);
                    this.dropTables();
                }

                this.db.transaction(function(tx){
                    self.createTables();
                });
            }
        } catch(err) {
            console.log("Error opening database: " + err);
        }
    }

    return this;
}

DBConnection.prototype.dropTables = function() {
    console.log("dropTables");
    var self = this;
    if(this.db) {
        this.db.transaction(function(tx){
            tx.executeSql("DROP TABLE settings");
            tx.executeSql("DROP TABLE datajson");
            tx.executeSql("DROP TABLE stops");
            tx.executeSql("DROP TABLE recent");
            self.createTables();
        });
    }
}

DBConnection.prototype.createTables = function() {
    if(this.db) {
        var self = this;
        try {
            this.db.transaction(function(tx){
                tx.executeSql("CREATE TABLE IF NOT EXISTS settings(key TEXT UNIQUE, value TEXT)");
                tx.executeSql("CREATE TABLE IF NOT EXISTS datajson(key TEXT UNIQUE, date DATETIME DEFAULT CURRENT_TIMESTAMP, value TEXT)");
                tx.executeSql("CREATE TABLE IF NOT EXISTS stops(ID INTEGER PRIMARY KEY AUTOINCREMENT, key TEXT, item INTEGER, listId INTEGER, value TEXT, coorX REAL, coorY REAL, UNIQUE (key, item) ON CONFLICT REPLACE)");
                tx.executeSql("CREATE TABLE IF NOT EXISTS recent(ID INTEGER PRIMARY KEY AUTOINCREMENT, date DATETIME DEFAULT CURRENT_TIMESTAMP, typeid TEXT, stopidfrom INTEGER, stopidto INTEGER, stopidvia INTEGER, CONSTRAINT unq UNIQUE (typeid, stopidfrom, stopidto, stopidvia))");
            });
        } catch(err) {
            console.log("Error creating table in database: " + err);
        }
    }
    return this;
}

DBConnection.prototype.clearSettingsTable = function() {
    if(this.db) {
        try {
            this.db.transaction(function(tx){
                tx.executeSql("DELETE from settings");
            });
        } catch(err) {
            console.log("Error deleting user data: " + err);
        };
    }
}

DBConnection.prototype.saveSetting = function(key, value) {
    if(this.db) {
        this.db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO settings VALUES(?, ?)', [key, value]);
        });
    }
}

DBConnection.prototype.getSetting = function(key) {
    if(this.db) {
        var returnValue = null;
        this.db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT value FROM settings WHERE key=?', [key]);
            if(rs.rows.item(0)) {
                returnValue = rs.rows.item(0).value;
            }
        });
        return returnValue;
    }
    return false;
}

DBConnection.prototype.clearDataJSONTable = function() {
    if(this.db) {
        try {
            this.db.transaction(function(tx){
                tx.executeSql("DELETE from datajson");
            });
        } catch(err) {
            console.log("Error deleting user data: " + err);
        };
    }
}

DBConnection.prototype.saveDataJSON = function(key, value) {
    if(this.db) {
        this.db.transaction(function(tx) {
            tx.executeSql('INSERT OR REPLACE INTO datajson(key, value) VALUES(?, ?)', [key, value]);
        });
    }
}

DBConnection.prototype.getDataJSON = function(key) {
    if(this.db) {
        var returnValue = null;
        this.db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT key,date,value FROM datajson WHERE key=?', [key]);
            var item = rs.rows.item(0);
            if(item) {
                returnValue = {
                    key: item.key,
                    date: item.date,
                    value: item.value
                };
            }
        });
        return returnValue;
    }
    return false;
}

DBConnection.prototype.clearStations = function() {
    if(this.db) {
        try {
            this.db.transaction(function(tx){
                tx.executeSql("DELETE from stops");
            });
        } catch(err) {
            console.log("Error deleting user data: " + err);
        };
    }
}

DBConnection.prototype.clearStationsForId = function(transportId) {
    console.log("Deleting stops for transport option with id: " + transportId);
    if(this.db) {
        try {
            this.db.transaction(function(tx){
                tx.executeSql("DELETE from stops where key=?", [transportId]);
            });
        } catch(err) {
            console.log("Error deleting stops for " + transportId + ": " + err);
        };
    }
}

DBConnection.prototype.saveStation = function(key, data) {
    if(this.db) {
        data = data || {};
        if(data.value && data.item && data.coorX && data.coorY) {
            this.db.transaction(function(tx) {
                tx.executeSql('INSERT OR REPLACE INTO stops(key, value, item, listId, coorX, coorY) VALUES(?, ?, ?, ?, ?, ?)', [key, data.value, data.item, data.listId, data.coorX, data.coorY]);
            });
        }
    }
}

DBConnection.prototype.getStationsByName = function(key, value) {
    if(this.db) {
        var startsWithMatches = [];
        var laterMatches = [];
        var searchBaseString = GeneralTranport.baseString(value);

        this.db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT ID,key,value,item,listId,coorX,coorY FROM stops WHERE key=? ORDER BY value ASC", [key]);
            for(var i = 0; i < rs.rows.length; i++) {
                if(typeof rs.rows.item(i) !== typeof undefined && rs.rows.item(i).value) {
                    if(startsWithMatches.length <= 10) {
                        var item = rs.rows.item(i);
                        var stopObj = {
                            key: item.key,
                            value: item.value,
                            item: item.item,
                            listId: item.listId,
                            coorX: item.coorX,
                            coorY: item.coorY
                        };

                        var dbStopBaseString = GeneralTranport.baseString(item.value);
                        if(dbStopBaseString.indexOf(searchBaseString) === 0) {
                            startsWithMatches.push(stopObj);
                        }
                        else if(dbStopBaseString.indexOf(searchBaseString) > -1) {
                            laterMatches.push(stopObj);
                        }
                    }
                }
            }
        });

        var returnValue = startsWithMatches.concat(laterMatches);
        return returnValue.slice(0, 10);
    }
    return false;
}

DBConnection.prototype.getStationByValue = function(key, value) {
    if(this.db) {
        var returnValue = null;
        this.db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT ID,key,value,item,listId,coorX,coorY FROM stops WHERE key=? AND value=?', [key, value]);
            var item = rs.rows.item(0);
            if(item) {
                returnValue = {
                    key: item.key,
                    value: item.value,
                    item: item.item,
                    listId: item.listId,
                    coorX: item.coorX,
                    coorY: item.coorY
                };
            }
        });
        return returnValue;
    }
    return false;
}

DBConnection.prototype.getAllUsedTypesFromSavedStations = function() {
    if(this.db) {
        var returnValue = [];
        this.db.transaction(function(tx) {
            var rs = tx.executeSql('SELECT DISTINCT key FROM stops');
            var item = rs.rows;
            for(var i = 0; i < rs.rows.length; i++) {
                if(item.item(i).key) {
                    returnValue.push(item.item(i).key);
                }
            }
        });
        return returnValue;
    }
    return false;
}

// Append new search to history
DBConnection.prototype.appendSearchToHistory = function(search) {
    var success = false;
    if(this.db) {
        if(search) {
            var self = this;
            this.db.transaction(function(tx) {
                var countOfLines = tx.executeSql("SELECT Count(*) as count FROM recent").rows.item(0).count;
                var linesAffected = 0;
                var limit = 80;

                if(!search.from || !search.to) {
                    console.log("Can't save history entry without initial and final station.");
                    success = false;
                    return false;
                }
                if(!search.via) {
                    search.via = -1;
                }
                var matchedLines = tx.executeSql("SELECT Count(*) as count FROM recent WHERE typeid=? AND stopidfrom=? AND stopidto=? AND stopidvia=?", [search.id, search.from, search.to, search.vis]);
                if(matchedLines.rows.item(0).count <= 0) {
                    if(countOfLines < limit) {
                        linesAffected = tx.executeSql("INSERT OR REPLACE INTO recent(typeid, stopidfrom, stopidto, stopidvia) VALUES(?, ?, ?, ?)", [search.id, search.from, search.to, search.via]);
                        if(linesAffected.rowsAffected !== 1) {
                            console.log("An error occured while creating or updating search history.");
                        }
                    }
                    else {
                        linesAffected = tx.executeSql("DELETE FROM recent WHERE ID in (SELECT ID FROM recent AS selector INNER JOIN (SELECT ID as sid, date FROM recent ORDER BY date LIMIT 1) AS limited ON selector.ID = limited.sid)");
                        if(linesAffected.rowsAffected !== 1) {
                            console.log("An error occured while deleting an entry in the search history.");
                        }

                        success = self.appendSearchToHistory(search);
                        return false;
                    }
                }
                else {
                    var dbFix = tx.executeSql("SELECT * FROM recent");
                    var fixed = false;
                    for(var i = 0; i < dbFix.rows.length; i++) {
                        if(!dbFix.rows.item(i).stopidfrom || !dbFix.rows.item(i).stopidto) {
                            if(dbFix.rows.item(i).ID) {
                                self.deleteSearchHistory(dbFix.rows.item(i).ID);
                                fixed = true;
                            }
                            else {
                                self.deleteAllSearchHistory();
                                fixed = true;
                                console.log("Search histroy deleted due to a DB error");
                            }
                        }
                    }
                    if(fixed) {
                        return self.appendSearchToHistory(search);
                    }

                    linesAffected = tx.executeSql("INSERT OR REPLACE INTO recent(ID, typeid, stopidfrom, stopidto, stopidvia) VALUES(?, ?, ?, ?, ?)", [matchedLines.rows.item(0).id, search.id, search.from, search.to, search.via]);
                }

                if(linesAffected.rowsAffected !== 1) {
                    console.log("An error occured while creating or updating search history.");
                    success = false;
                }
            });
        }
    }
    return success;
}

// Delete all search history by ID
DBConnection.prototype.deleteAllSearchHistory = function() {
    if(this.db) {
        this.db.transaction(function(tx) {
            var linesAffected = tx.executeSql("DELETE FROM recent");
            if(linesAffected.rowsAffected < 1) {
                console.log("Nothing was deleted in the search history.");
            }
        });
    }
}

// Delete search history by ID
DBConnection.prototype.deleteSearchHistory = function(id) {
    if(this.db) {
        this.db.transaction(function(tx) {
            var linesAffected = tx.executeSql("DELETE FROM recent WHERE ID=?", [id]);
            if(linesAffected.rowsAffected !== 1) {
                console.log("Nothing was deleted in the search history.");
            }
        });
    }
}

// Get a list of recent search history
// Returns ID, typeid, date, typename and names: stopfrom, stopto and stopvia + coordinates like stopfromx and stopfromy
DBConnection.prototype.getSearchHistory = function() {
    var searches = [];
    if(this.db) {
        this.db.transaction(function(tx) {
            var rs = tx.executeSql("SELECT date, typeid, recent.ID as ID, stopidfrom, stopsfrom.value as stopnamefrom, stopidto, stopsto.value as stopnameto, stopidvia, stopsvia.value as stopnamevia FROM recent INNER JOIN stops stopsfrom ON (stopidfrom = stopsfrom.item) INNER JOIN stops stopsto ON (stopidto = stopsto.item) LEFT JOIN stops stopsvia ON (stopidvia = stopsvia.item) ORDER BY date DESC");
            for(var i = 0; i < rs.rows.length; i++) {
                searches.push(rs.rows.item(i));
            }
        });
    }
    return searches;
}
