//
//  NotepadViewModel.swift
//  TacBoard
//
//  Created by Vig, Christopher on 8/3/20.
//  Copyright © 2020 Christopher Vig. All rights reserved.
//

import Foundation
import ReactiveSwift
import UIKit

/// View model for the notepad pages.
class NotepadViewModel {
    
    // MARK: Fields
    
    private var pathsLookup: [NotepadPage: MutableProperty<[NotepadPath]>]
    private var activePathLookup: [NotepadPage: MutableProperty<NotepadPath?>]
    private var isEmptyLookup: [NotepadPage: Property<Bool>]
    
    // MARK: Initialization
    
    /// Initializes a new instance with the specified settings manager.
    init(settingsManager: SettingsManager = SettingsManager.shared) {
        
        // Persisted properties
        self.selectedPage = settingsManager.notepadSelectedPage
        self.selectedPathColor = settingsManager.notepadSelectedPathColor
        self.selectedPathWidth = settingsManager.notepadSelectedPathWidth

        self.pathsLookup = NotepadPage.allCases.reduce(into: [:]) { lookup, page in
            lookup[page] = MutableProperty([])
        }
        self.activePathLookup = NotepadPage.allCases.reduce(into: [:]) { lookup, page in
            lookup[page] = MutableProperty(nil)
        }
        
        // Derived properties
        let pathsLookup = self.pathsLookup // ugh
        self.isEmptyLookup = NotepadPage.allCases.reduce(into: [:]) { lookup, page in
            lookup[page] = Property(initial: false, then: pathsLookup[page]!.producer.map { $0.isEmpty })
        }
        
    }
    
    // MARK: Properties
    
    /// The currently selected notepad page.
    let selectedPage: MutableProperty<NotepadPage>
    
    /// The currently active path color.
    let selectedPathColor: MutableProperty<UIColor>
    
    /// The currently active path width.
    let selectedPathWidth: MutableProperty<CGFloat>

    /// The color to be used for the currently active path.
    lazy var activePathColor: Property<UIColor> = {
        return Property(self.selectedPathColor)
    }()
    
    /// The line width to be used for the currently active path.
    lazy var activePathWidth: Property<CGFloat> = {
        let producer = SignalProducer.combineLatest(self.selectedPathColor.producer, self.selectedPathWidth.producer)
        return Property(initial: self.selectedPathWidth.value, then: producer.map { (color, width) -> CGFloat in
            if color.isEqualToColor(UIColor(application: .notepadBackground)) {
                
                // If the eraser is selected, then make the pen wider to make it easier to erase things
                return width * 4.0
                
            } else {
             
                // Otherwise, just use the user-selected width
                return width
                
            }
        })
    }()
    
    /// Returns a `MutableProperty` containing the paths for the specified page.
    func paths(page: NotepadPage) -> MutableProperty<[NotepadPath]> {
        return pathsLookup[page]! // guaranteed non-nil
    }
    
    /// Returns a `MutableProperty` containing the active path for the specified page, or `nil` if there is no active path.
    func activePath(page: NotepadPage) -> MutableProperty<NotepadPath?> {
        return activePathLookup[page]! // guaranteed non-nil
    }
    
    /// Returns a `Property` containing `true` if the specified page has no paths.
    func isEmpty(page: NotepadPage) -> Property<Bool> {
        return isEmptyLookup[page]! // guaranteed non-nil
    }

}
