#Butter#

Butter is a framework for OS X that seeks to provide a set of commonly used controls which are full replacements for their cell-based AppKit counterparts. This framework is still a work in progress, but it is **usable in production apps.**

This framework seeks to provide the following:

- Image-based customization of controls for various states
- Block-based action handlers
- Complete independence of cell-based controls
- Customizable properties that would otherwise be hard to change

#Controls#

##BTRControl##
`BTRControl` is a subclass of `BTRView` that provides a base for all controls. It offers state-based customization with block-based (or alternatively target/action-based) control event handling. `BTRControl` is designed for subclassing.

More controls will be added in due time if seen fit.

`BTRCollectionView` can be found on its [own repo.](https://github.com/ButterKit/BTRCollectionView)

License
---
Butter is licensed under the MIT License. See the [License](https://github.com/ButterKit/Butter/blob/master/LICENSE.md).