DMCoreDataUtils
===============

### Utilities methods for Apple's Core Data Storage.


#### **By Daniele Margutti**
* **mail**: [me@danielemargutti.com](mail:me@danielemargutti.com)
* **web**: [www.danielemargutti.com](http://www.danielemargutti.com)

Licensed under [MIT License](http://opensource.org/licenses/MIT)

A set of utilities for Core Data under iOS and OS X.

Currently implements:

## Primary Key/Unique Objects supports for NSManagedObject

These methods allows you to implement an optimized check for uniqueness of a particular key inside a Core Data Storage. As you know Core Data is not a relational database so you can't specify (at least for now) a primary key for an attribute of an entity (NSManagedObject),

so you need to check manually if an existing object with a particular key is already present inside the storage.
If you have a set of elements (ie. taken from a remote call) and you want to insert them maintaining a primary key constraint you need to make a lots of boring checks.

These methods allows you to pass an array of objects (must respond to KVO,so an NSArray of NSDictionaries is good!) and return which elements are new to the context, which ones already exists and which ones are removed.

All in an pretty easy way!

Required parameters are:

* **remoteItemsArray**: an NSArray of the objects you want to insert into the managed object context. Each object inside the array must respond to
* **valueForKey**: method (KVO compliant)
* **remoteUniqueKey**:    our primary key string to check for remote objects
* **localEntityName**:    which NSManagedObject represent our list of remoteItemsArray? You must pass an NSString
* **localUniqueKey**:     which NSManagedObject key is our local primary key? (generally it should be the same of remoteUniqueKey)
* **options**:            an NSDictionary which can contain several keys:
  * **DMUOOptionsKeysAreNumbers** (NSNumber as BOOL): should specified primary key be treated as an numeric value (it's important for our algorithm)
  * **DMUOOptionsAdditionalPredicate** (NSPredicate) [DEFAULT IS NIL]: you can specify an additional predicate used to fetch local objects used to compare with our remote list.
  * **DMUOOptionsReturnOnlyIndexes** (NSNumber as BOOL) [DEFAULT YES]: returns values must contain only indexes (NSIndexesSet) of the object or the objects itself? turning it off (FALSE) will speed up the fetch. If you don't need to have the list of
                                    local (already presents) NSManagedObject's back to the function you can turn it off.
  * **DMUOOptionsKeyComparisionIsCaseSensitive** (NSNumber as BOOL) [DEFAULT YES]: key comparision is case sensitive due to performance reasons; so both your local and remote primary keys should be with same capitalization (upper or lower case, not mixed). (case insentive compare is slower).
 
 
Function returns (as block):

* **remoteOrdObjects**: an ordered version of passed remoteItemsArray. You should use this array combined with returned indexes. (ie. if you have newItems as index array with index 4, the new item value should be taken as id newObject = [remoteOrdObjects objectAtIndex:index] do not use passed remoteItemsArray as reference for results indexes)
* **localOrdObjects**: 
  * if *[DMUOOptionsReturnOnlyIndexes is TRUE]* this is an NSArray of NSDictionaries which represent our local stored keys (each array contains only your localUniqueKey attribute)
  * if *[DMUOOptionsReturnOnlyIndexes is FALSE]* this array contains fetched NSManagedObject's entities.
* **newItems**: 
  * if *[DMUOOptionsReturnOnlyIndexes is FALSE]* this is an NSIndexSet with a list of remoteOrdObjects not present in your local store. 
  * if *[DMUOOptionsReturnOnlyIndexes is TRUE]* this is an NSArray of your's remoteItemsArray not present in your local store
* **existingItems**: 
  * if *[DMUOOptionsReturnOnlyIndexes is FALSE]* this is an NSIndexSet with a list of remoteOrdObjects already present in your local store
  * if* [DMUOOptionsReturnOnlyIndexes is TRUE]* this is an NSArray of your's remoteItemsArray already present in your local store. Each element is an NSArray of two elements: at index 0 you have your remoteOrdObjects representation, at index 1 you have your's stored NSManagedObjec representation.
* **removedItems**:
  * if *[DMUOOptionsReturnOnlyIndexes is FALSE]* this is an NSIndexSet with a list of remoteOrdObjects removed from your local store
  * if *[DMUOOptionsReturnOnlyIndexes is TRUE]* this is an NSArray of your's remoteItemsArray removed from your local store
* **error**: nil if no error has occurred during the call, otherwise a description of the error occurred (other params are nil)
