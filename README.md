# ParticlePullToRefresh

![Example](https://raw.githubusercontent.com/10clouds/ParticlePullToRefresh-iOS/master/example.gif)

## Example

To run the example project clone the repo and run `Example` target

## Requirements

- Xcode 9
- Swift 4.1
- iOS 11

## Installation

ParticlePullToRefresh doesn't contain any external dependencies

### [CocoaPods](https://cocoapods.org)

```ruby
pod 'ParticlePullToRefresh'
```

## Usage

Add pull-to-refresh to the scroll view subclass and provide an action closure. Call `endRefreshing()` when you are done to finish the animation

```swift
tableView.addParticlePullToRefresh { [weak self] in
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    self?.tableView.particlePullToRefresh?.endRefreshing()
  }
}
```

Remove pull-to-refresh on `deinit`

```swift
deinit {
  tableView.removeParticlePullToRefresh()
}
```

## Customization

You can optionally pass the color when you add pull-to-refresh to the scroll view subclass

```swift
tableView.addParticlePullToRefresh(color: .yellow) { [weak self] in
  DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
    self?.tableView.particlePullToRefresh?.endRefreshing()
  }
}
```

## Author

Alex Demchenko, alex.demchenko@10clouds.com

## License

ParticlePullToRefresh is available under the MIT license. See the LICENSE file for more info.
