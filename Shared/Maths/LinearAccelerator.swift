//
//  LinearAccelerator.swift
//  Decipher
//
//  Created by Jack Copsey on 17/11/2020.
//

import Foundation

struct LinearAccelerator {
    let startPoint: Double
    let inflectPoint1: Double
    let inflectPoint2: Double
    let endPoint: Double
    
    let startTime: Double    // moment when particle begins motion
    let inflectTime1: Double // moment when particle stops accelerating (= reaches max. velocity)
    let inflectTime2: Double // moment when particle starts decelerating
    let endTime: Double      // moment when particle finishes motion
    
    let totalDisplacement: Double // difference between start point and end point
    let totalDistance: Double     // total distance covered by the particle over its motion
    let direction: Double    // direction of travel (either +1 or -1)
    let peakSpeed: Double    // peak absolute change in position per unit of time
    let acceleration: Double // change in velocity per unit of time
    
    init(startPoint: Double, endPoint: Double, initialTime: Double, maxSpeed: Double, acceleration: Double) {
        self.totalDisplacement = endPoint - startPoint
        self.totalDistance = totalDisplacement.magnitude
        self.direction = endPoint > startPoint ? +1 : -1
        self.acceleration = acceleration
        
        // Case 1: the particle never reaches its maximum velocity, because the displacement
        // is too small.
        //
        // The graph of velocity across time looks like this:
        //
        //
        //        /\
        // ______/  \__________
        //
        if maxSpeed * maxSpeed > totalDistance * acceleration {
            let accelerationDur = sqrt(totalDistance / acceleration)
            
            self.startTime = initialTime
            self.inflectTime1 = startTime + accelerationDur
            self.inflectTime2 = inflectTime1
            self.endTime = inflectTime2 + accelerationDur
            
            self.startPoint = startPoint
            self.inflectPoint1 = startPoint + 0.5 * totalDisplacement
            self.inflectPoint2 = inflectPoint1
            self.endPoint = endPoint
            
            self.peakSpeed = sqrt(totalDistance * acceleration)
        }
        
        // Case 2: the particle reaches its maximum velocity.
        //
        // The graph of velocity across time looks like this:
        //
        //       ___
        //      /   \
        //     /     \
        // ___/       \__________
        //
        else {
            let accelerationDur = maxSpeed / acceleration
            let cruiseDur = (totalDistance / maxSpeed) - (maxSpeed / acceleration)
            
            self.startTime = initialTime
            self.inflectTime1 = startTime + accelerationDur
            self.inflectTime2 = inflectTime1 + cruiseDur
            self.endTime = inflectTime2 + accelerationDur
            
            self.startPoint = startPoint
            self.inflectPoint1 = startPoint + direction * 0.5 * maxSpeed * maxSpeed / acceleration
            self.inflectPoint2 = inflectPoint1 + direction * maxSpeed * cruiseDur
            self.endPoint = endPoint
            
            self.peakSpeed = maxSpeed
        }
    }
    
    /// Get the particle's position at the specified time.
    func position(at time: Double) -> Double {
        if time < startTime {
            return startPoint
        } else if time < inflectTime1 {
            let dt = time - startTime
            let distance = 0.5 * acceleration * dt * dt
            return startPoint + direction * distance
        } else if time < inflectTime2 {
            let dt = time - inflectTime1
            let distance = peakSpeed * dt
            return inflectPoint1 + direction * distance
        } else if time < endTime {
            let dt = time - inflectTime2
            let distance = peakSpeed * dt - 0.5 * acceleration * dt * dt
            return inflectPoint2 + direction * distance
        } else {
            return endPoint
        }
    }
    
    /// Get the particle's signed velocity at the specified time.
    func velocity(at time: Double) -> Double {
        let speed: Double
        
        if time < startTime {
            speed = 0
        } else if time < inflectTime1 {
            let dt = time - startTime
            speed = acceleration * dt
        } else if time < inflectTime2 {
            speed = peakSpeed
        } else if time < endTime {
            let dt = time - inflectTime2
            speed = peakSpeed - acceleration * dt
        } else {
            speed = 0
        }
        
        return speed * direction
    }
    
    /// The total amount of time the particle spends in motion.
    var totalDuration: Double {
        endTime - startTime
    }
    
    /// Returns `true` if the animation will have completed at the specified time.
    /// Otherwise returns `false`.
    func hasFinished(at time: Double) -> Bool {
        time >= endTime
    }
}
