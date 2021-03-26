//
//  Wrapper.swift
//  
//
//  Created by Steven W. Klassen on 2021-03-25.
//

import Foundation

// TODO: move this into KSSCore?


/**
 Simple wrapper class to be used when you need a pass-by-value object, like
 a struct, to outlive its scope.

 */
class Wrapper<Struct> {
    var object: Struct? = nil
}
