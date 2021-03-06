///===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2019 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

extension vDSP {
    
    /// An enum that specifies which DCT variant to perform.
    @available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
    public enum DCTTransformType: CaseIterable {
        case II
        case III
        case IV
        
        public var dctType: vDSP_DCT_Type {
            switch self {
            case .II:
                return .II
            case .III:
                return .III
            case .IV:
                return .IV
            }
        }
    }
    
     /// A class that provides single-precision discrete cosine transform.
    @available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
    public class DCT {
        
        fileprivate let dctSetup: vDSP_DFT_Setup
        
        /// Initializes a new discrete cosine transform instance.
        ///
        /// - Parameter previous: a previous vDSP_DCT instance to share data with.
        /// - Parameter count: the number of real elements to be transformed.
        /// - Parameter transformType: Specifies the transform type (type II for forward and type III for inverse).
        public init?(previous: DCT? = nil,
                     count: Int,
                     transformType: DCTTransformType) {
            
            guard let setup = vDSP.VectorizableFloat.makeDCTSetup(previous: previous,
                                                                  count: count,
                                                                  transformType: transformType) else {
                                                                    return nil
            }
            
            dctSetup = setup
        }
        
        /// Returns the single-precision real discrete cosine transform.
        ///
        /// - Parameter input: Real input vector.
        /// - Returns: Real output vector.
        @available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
        @inline(__always)
        public func transform<U>(_ vector: U) -> [Float]
            where
            U: AccelerateBuffer,
            U.Element == Float {
                
                let result = Array<Float>(unsafeUninitializedCapacity: vector.count) {
                    buffer, initializedCount in
                    
                    transform(vector,
                              result: &buffer)
                    
                    initializedCount = vector.count
                }
                
                return result
        }
        
        /// Computes an out-of-place single-precision real discrete cosine transform.
        ///
        /// - Parameter input: Real input vector.
        /// - Parameter output: Real output vector.
        @available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
        @inline(__always)
        public func transform<U, V>(_ vector: U, result: inout V)
            where
            U: AccelerateBuffer,
            V: AccelerateMutableBuffer,
            U.Element == Float, V.Element == Float {
                
                vDSP.VectorizableFloat.transform(dctSetup: dctSetup,
                                                 source: vector,
                                                 destination: &result)
        }
        
        deinit {
            vDSP_DFT_DestroySetup(dctSetup)
        }
    }
}

@available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
fileprivate protocol vDSP_FloatingPointDiscreteCosineTransformable: BinaryFloatingPoint {
    associatedtype DCTFunctions: vDSP_DCTFunctions where DCTFunctions.Scalar == Self
}

@available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
extension Float: vDSP_FloatingPointDiscreteCosineTransformable {
    typealias DCTFunctions = vDSP.VectorizableFloat
}

@available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
fileprivate protocol vDSP_DCTFunctions {
    associatedtype Scalar
    
    @inline(__always)
    static func makeDCTSetup(previous: vDSP.DCT?,
                             count: Int,
                             transformType: vDSP.DCTTransformType) -> OpaquePointer?
    
    @inline(__always)
    static func transform<U, V>(dctSetup: OpaquePointer,
                                source: U,
                                destination: inout V)
        where
        U: AccelerateBuffer,
        V: AccelerateMutableBuffer,
        U.Element == Scalar, V.Element == Scalar
}

@available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
extension vDSP.VectorizableFloat: vDSP_DCTFunctions {
    
    @available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
    @inline(__always)
    fileprivate static func makeDCTSetup(previous: vDSP.DCT? = nil,
                                    count: Int,
                                    transformType: vDSP.DCTTransformType) -> OpaquePointer? {
        
        return vDSP_DCT_CreateSetup(previous?.dctSetup,
                                    vDSP_Length(count),
                                    transformType.dctType)
    }
    
    @available(iOS 9999, OSX 9999, tvOS 9999, watchOS 9999, *)
    @inline(__always)
    fileprivate static func transform<U, V>(dctSetup: OpaquePointer,
                                       source: U,
                                       destination: inout V)
        where
        U: AccelerateBuffer,
        V: AccelerateMutableBuffer,
        U.Element == Float,
        V.Element == Float {
            
            destination.withUnsafeMutableBufferPointer { dest in
                source.withUnsafeBufferPointer { src in
                    vDSP_DCT_Execute(dctSetup,
                                     src.baseAddress!,
                                     dest.baseAddress!)
                }
            }
    }
}


