//
//  NSManagedObjectContext+DMExtras.m
//  Shake2
//
//  Created by daniele on 12/10/12.
//  Copyright (c) 2012 danielemargutti. All rights reserved.
//

#import "NSManagedObjectContext+DMExtras.h"

NSString * const DMUOOptionsKeysAreNumbers                  = @"DMUOOptionsKeysAreNumbers";
NSString * const DMUOOptionsAdditionalPredicate             = @"DMUOOptionsAdditionalPredicate";
NSString * const DMUOOptionsReturnOnlyIndexes               = @"DMUOOptionsReturnOnlyIndexes";
NSString * const DMUOOptionsKeyComparisionIsCaseSensitive   = @"DMUOOptionsKeyComparisionIsCaseSensitive";

@implementation NSManagedObjectContext (DMUniqueObjects)

- (void) compareItems:(NSArray *) remoteItemsArray
             usingKey:(NSString *) remoteUniqueKey
                 with:(NSString *) localEntityName
         keyIsNumeric:(BOOL) isKeyNumeric
         completition:(void (^)(id remoteOrdObjects,id localOrdObjects, id newItems,id existingItems,id removedItems,NSError *error)) completition {
    
    return [self compareItems:remoteItemsArray
                     usingKey:remoteUniqueKey
                         with:localEntityName
                     usingKey:remoteUniqueKey
                      options:@{DMUOOptionsKeysAreNumbers                   : @(isKeyNumeric),
                                DMUOOptionsReturnOnlyIndexes                : @(YES),
                                DMUOOptionsKeyComparisionIsCaseSensitive    : @(YES)}
                 completition:completition];
}

- (void) compareItems:(NSArray *) remoteItemsArray
             usingKey:(NSString *) remoteUniqueKey
                 with:(NSString *) localEntityName
             usingKey:(NSString *) localUniqueKey
              options:(NSDictionary *) optionsDictionary
         completition:(void (^)(id remoteOrdObjects,id localOrdObjects, id newItems,id existingItems,id removedItems,NSError *error)) completition {
    
    NSEntityDescription* localEntity = [NSEntityDescription entityForName:localEntityName
                                                   inManagedObjectContext:self];
    if (localEntity == nil) {
        completition(nil,nil,nil,nil,nil,[NSError errorWithDomain:[NSString stringWithFormat:@"Entity [%@] does not exist in this context",localEntity]
                                                     code:0
                                                 userInfo:nil]);
        return;
    }
    if (remoteItemsArray.count == 0) {
        completition(nil,nil,nil,nil,nil,[NSError errorWithDomain:@"Source array does is empty" code:0 userInfo:nil]);
        return;
    }
    
    BOOL returnOnlyIndexes = [[optionsDictionary objectForKey:DMUOOptionsReturnOnlyIndexes] boolValue];

    // We want to fetch a list of our stored object's localUniqueKey
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:localEntityName];
    [request setReturnsDistinctResults:YES];
    if (returnOnlyIndexes) {
        [request setPropertiesToFetch:@[localUniqueKey]];
        [request setResultType:NSDictionaryResultType];
    } else
        [request setResultType:NSManagedObjectResultType];
    
    // Attach an optional filter predicate
    if ([optionsDictionary objectForKey:DMUOOptionsAdditionalPredicate] != nil)
        [request setPredicate:[optionsDictionary objectForKey:DMUOOptionsAdditionalPredicate]];
    
    BOOL keyIsNumeric = [[optionsDictionary objectForKey:DMUOOptionsKeysAreNumbers] boolValue];
    
    NSSortDescriptor *sortDescription = nil;
    if (keyIsNumeric)
        // Sort result key as numeric values
        sortDescription = [[NSSortDescriptor alloc] initWithKey:localUniqueKey
                                                      ascending:YES
                                                     comparator:^NSComparisonResult(id obj1, id obj2) {
                                                         return [[obj1 valueForKey:localUniqueKey] compare:[obj2 valueForKey:localUniqueKey] options:NSNumericSearch];
                                                     }];
    else
        // Sort result key as string values
        sortDescription = [NSSortDescriptor sortDescriptorWithKey:localUniqueKey ascending:YES];
    
    // Set sort description
    [request setSortDescriptors:@[sortDescription]];
        
    NSError *fetchError = nil;
    NSMutableArray *fetchedItems = [NSMutableArray arrayWithArray:[self executeFetchRequest:request error:&fetchError]];
    if (fetchError) {
        completition(nil,nil,nil,nil,nil,fetchError);
        return;
    }
    
    // return a list of local keys
    NSArray *localKeys = [fetchedItems valueForKey:localUniqueKey];
    // get a list of remote object's keys ordered
    NSMutableArray *remoteOrderedObjects = [NSMutableArray arrayWithArray:remoteItemsArray];
    [remoteOrderedObjects sortUsingDescriptors:@[sortDescription]];
    // get a list of remote ordered keys
    NSArray *remoteKeys = [remoteOrderedObjects valueForKey:remoteUniqueKey];

    NSMutableIndexSet *setRemovedItems = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *setNewItems = [[NSMutableIndexSet alloc] init];
    NSMutableIndexSet *setExistingItems = [[NSMutableIndexSet alloc] init];
    NSMutableArray *arrayExistingItems = nil;
    if (!returnOnlyIndexes) arrayExistingItems = [[NSMutableArray alloc] init];

    NSString *currentLocalKey = nil;
    NSString *currentRemoteKey = nil;
    NSInteger localIndex = 0;
    NSInteger remoteIndex = 0;
    
    BOOL caseSensitiveKeyComparision  = [[optionsDictionary objectForKey:DMUOOptionsKeyComparisionIsCaseSensitive] boolValue];
    
    while (remoteIndex < remoteKeys.count) {
        currentRemoteKey = [remoteKeys objectAtIndex:remoteIndex];
        
        if (localIndex >= localKeys.count) {
            // We are over the bounds of our stored local key.
            // Each remote key after this should be considered as a new key
            [setNewItems addIndex:remoteIndex];
            remoteIndex++;
        } else {
            currentLocalKey = [localKeys objectAtIndex:localIndex];
            NSComparisonResult compare = [currentRemoteKey compare:currentLocalKey
                                                           options:(keyIsNumeric ? NSNumericSearch :
                                                                    (caseSensitiveKeyComparision ? NSLiteralSearch : NSCaseInsensitiveSearch))];
            switch (compare) {
                case NSOrderedAscending:
                    // The left operand is smaller than the right operand.
                    // CurrentRemoteKey is a new item, not present in our local storage
                    [setNewItems addIndex:remoteIndex];
                    remoteIndex++;
                    break;
                case NSOrderedDescending:
                    // The left operand is greater than the right operand.
                    // CurrentLocalKey is removed from our remote keys list
                    [setRemovedItems addIndex:localIndex];
                    localIndex++;
                    break;
                case NSOrderedSame:
                default:
                    // The two operands are equal.
                    // CurrentLocalKey is present in remoteLocalKey
                    [setExistingItems addIndex:remoteIndex];
                    if (!returnOnlyIndexes)
                        [arrayExistingItems addObject:@[[fetchedItems objectAtIndex:localIndex],[remoteOrderedObjects objectAtIndex:remoteIndex]]];
                         
                    remoteIndex++;
                    localIndex++;
                    break;
            }
        }
    }

    if (returnOnlyIndexes)
        completition(remoteOrderedObjects,
                     fetchedItems,
                     setNewItems,
                     setExistingItems,
                     setRemovedItems,nil);
    else
        completition(remoteOrderedObjects,
                     fetchedItems,
                     [remoteOrderedObjects objectsAtIndexes:setNewItems],
                     arrayExistingItems,
                     [remoteOrderedObjects objectsAtIndexes:setRemovedItems],
                     nil);
}



- (NSArray *) objectsOfType:(NSString *) className
             usingPredicate:(NSPredicate *) predicate
                   sortedBy:(NSString *) sortKey
                  ascending:(BOOL) asceding
                      limit:(NSInteger) limitNo {


    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:className];
    [request setResultType:NSManagedObjectResultType];
    
    if (sortKey != nil)
        [request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:sortKey ascending:asceding]]];
    
    if (limitNo > 0) [request setFetchLimit:limitNo];
    if (predicate != nil) [request setPredicate:predicate];
        
    NSError *err = nil;
    NSArray *list = [self executeFetchRequest:request error:&err];
    if (err != nil) {
        return nil;
    } else {
        return list;
    }
}

- (NSUInteger) countObjectsOfType:(NSString *) className
                   usingPredicate:(NSPredicate *) predicate {

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:className];
    if (predicate != nil) [request setPredicate:predicate];
    
        
    NSError *err = nil;
    NSInteger total = [self countForFetchRequest:request error:&err];
    if (err != nil) {
        return 0;
    } else {
        return total;
    }
}


@end
