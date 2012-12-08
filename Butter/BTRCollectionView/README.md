INDCollectionView
=================

This is an in-progress port of [Peter Steinberger's](https://github.com/steipete) [PSTCollectionView](https://github.com/steipete/PSTCollectionView) to AppKit. 

### Based on commit [308ddcc](https://github.com/steipete/PSTCollectionView/commit/308ddccebdcaa19472711de950e8ce8c3258e2e7) of PSTCollectionView

(This will be updated as we merge in upstream changes)

## Goals

* Minimal changes to existing PSTCollectionView code in order to maintain the ability to easily merge in future changes
* Removal of iOS specific code and addition of methods to make this a first class citizen on OS X, with support for drag and drop and other desktop specific paradigms
* 10.8+ only in order to take advantage of all the new Core Animation goodies that will hopefully make this a performant class, even on AppKit

## Authors

This code was originally written by [Peter Steinberger](https://github.com/steipete). It is being ported to AppKit by [Indragie Karunaratne](http://github.com/indragiek) and [Jonathan Willing](http://github.com/jwilling)

## License

This fork is licensed under the same MIT license as the original. See the LICENSE file for more info.
