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

##BTRButton##
`BTRButton` is a subclass of `BTRControl`, and is an extremely customizable. Here's an example:

```objc
BTRButton *button = [[BTRButton alloc] initWithFrame:rect];
[button setTitle:@"Hey!" forControlState:BTRControlStateNormal];
[button setBackgroundImage:image1 forControlState:BTRControlStateNormal];
[button setBackgroundImage:image2 forControlState:BTRControlStateHighlighted];
[button addBlock:^{ NSLog(@"hi!"); } forControlEvents:BTRControlEventClick];
button.animatesContents = YES; // animate the transition back from click
```

##BTRActivityIndicator##
`BTRActvityIndicator` is a subclass of `BTRView` that provides a comprehensive API for creating any type of circular indeterminate activity indicator. Nearly all features of the indicator can be modified, and if more customization is desired a custom layer can be set to completely modify the appearance of the spinner. Short example:

```objc
BTRActivityIndicator *indicator = [[BTRActivityIndicator alloc] initWithFrame:rect];
indicator.progressShapeColor = newColor;
indicator.progressAnimationDuration = 4.f; // make it slow
indicator.progressShapeCount = 20; // give it more gears
[indicator startAnimating];
```


License
---
Butter is licensed under the MIT License. See the [License](https://github.com/ButterKit/Butter/blob/master/LICENSE.md).