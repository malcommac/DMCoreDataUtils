DMCoreDataUtils
===============

Utilities methods for Apple's Core Data Storage.

Currently implements:

- *Primary Key/Unique Objects supports*:  These methods allows you to implement an optimized check for uniqueness of a particular key inside a Core Data Storage.
    As you know Core Data is not a relational database so you can't specify (at least for now) a primary key for an attribute of an entity (NSManagedObject),
    so you need to check manually if an existing object with a particular key is already present inside the storage.
    If you have a set of elements (ie. taken from a remote call) and you want to insert them maintaining a primary key constraint you need to make a lots of
    boring checks.  These methods allows you to pass an array of objects (must respond to KVO,
    so an NSArray of NSDictionaries is good!) and return which elements are new to the context, which ones already exists and which ones are removed.
    All in an pretty easy way!