#import <Foundation/Foundation.h>

@class FMDatabaseQueue;

@interface FMMigrations : NSObject

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)db;
- (void)execute;

@end
