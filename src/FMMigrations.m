#import "Migrations.h"
#import "FMDatabaseQueue.h"
#import "FMDatabase.h"
#import "NSString+MD5.h"

NSString * MD5String(NSString *str) {
    const char *cstr = [str UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (unsigned int)strlen(cstr), result);

    return [NSString stringWithFormat:
        @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
        result[0], result[1], result[2], result[3],
        result[4], result[5], result[6], result[7],
        result[8], result[9], result[10], result[11],
        result[12], result[13], result[14], result[15]
    ];
}

@implementation FMMigrations {
    FMDatabaseQueue *_db;
}

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)db {
    if (self = [self init]) {
        _db = db;
    }

    return self;
}

- (void)execute {
    NSArray *migrations = [FMMigrations files];

    [self ensureMigrationsTableExists];

    for (NSURL *file in migrations) {
        [self executeMigrationAtURL:file];
    }
}

- (void)executeMigrationAtURL:(NSURL *)file {
    NSString *name = file.pathComponents.lastObject;

    NSError *err;
    NSString *script = [NSString stringWithContentsOfURL:file encoding:NSUTF8StringEncoding error:&err];

    if (err) {
        @throw [NSException exceptionWithName:@"MigrationException" reason:[NSString stringWithFormat:@"Unable to read migration file: %@", file.path] userInfo:nil];
    }

    NSString *existingHash = [self migrationHash:name];
    NSString *currentHash = MD5String(script);

    if (!existingHash) {
        // new migration, run it and insert a record into the migrations table

        __block BOOL ok = YES;

        [_db inTransaction:^(FMDatabase *db, BOOL *rollback) {
            ok = [db executeStatements:script];
            if (!ok) {
                *rollback = YES;
                return;
            }

            ok = [db executeUpdate:@"insert into migrations (filename, hash, executed) values (?, ?, ?)", name, currentHash, [NSDate date]];
            if (!ok) {
                *rollback = YES;
                return;
            }
        }];

        if (!ok) {
            @throw [NSException exceptionWithName:@"Migration failed" reason:@"Unable to execute script" userInfo:@{
                @"script": script
            }];
        }

        NSLog(@"Migrating: %@ completed", name);
    } else if (![currentHash isEqualToString:existingHash]) {
        // migration exists and has changed on disc
        NSLog(@"Migrating: %@ failed, migration changed", name);
        @throw [NSException exceptionWithName:@"MigrationException" reason:[NSString stringWithFormat:@"Migration file changed: %@", file.path] userInfo:nil];
    } else {
        // migration already run
        NSLog(@"Migrating: %@ skipped", name);
    }
}

- (NSString *)migrationHash:(NSString *)name {
    __block NSString *hash = nil;

    [_db inTransaction:^(FMDatabase *db, BOOL *rollback) {
        FMResultSet *set = [db executeQuery:@"select hash from migrations where filename = ?", name];

        if (set.next) {
            hash = [set stringForColumnIndex:0];
        }

        [set close];
    }];

    return hash;
}

- (void)ensureMigrationsTableExists {
    NSLog(@"Migrating: Initial migration setup");
    [self executeScript:@"create table if not exists migrations (filename text unique, hash text, executed text)"];
}

- (void)executeScript:(NSString *)script {
    __block BOOL ok;

    [_db inTransaction:^(FMDatabase *db, BOOL *rollback) {
        ok = [db executeUpdate:script];
        *rollback = !ok;
    }];

    if (!ok) {
        @throw [NSException exceptionWithName:@"Migration failed" reason:@"Unable to execute script" userInfo:@{
            @"script": script
        }];
    }
}

+ (NSArray *)files {
    NSURL *migrationsDirectory = [[[NSBundle mainBundle] resourceURL] URLByAppendingPathComponent:@"Migrations.bundle" isDirectory:YES];

    NSError *err;
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:migrationsDirectory includingPropertiesForKeys:@[] options:0 error:&err];

    if (err) {
        @throw [NSException exceptionWithName:@"MigrationException" reason:@"Unable to list migration directory" userInfo:nil];
    }

    return files;
}

@end
