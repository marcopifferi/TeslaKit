//
// Vehicle.swift
//  TeslaKit
//
//  Update by David Lüthi on 10.06.2021
//  based on code from Jaren Hamblin on 11/25/17.
//  Copyright © 2022 David Lüthi. All rights reserved.
//


import Foundation
import ObjectMapper

///
@available(macOS 13.1, *)
public struct Vehicle {
    public var allValues: Map

    /// The unique identifier of the vehicle
    public var id: String = ""

    /// The unique identifier of the vehicle (use id)
    public var vehicleId: Int = 0

    /// The unique identifier of the user of the vehicle
    public var userId: Int = 0

    /// The display name of the vehicle
    public var displayName: String = ""

    /// The options of the vehicle
    public var options: [VehicleOption] = []
	public var optionValues: [VehicleAllData] = []

    /// The vehicle's vehicle identification number
    public var vin: VIN?

    /// The vehicle's current state
    public var status: VehicleStatus = VehicleStatus.asleep

    /// The vehicle's remote start configuration
    public var remoteStartEnabled: Bool = false

    ///
    public var tokens: [String] = []

    ///
    public var inService: Bool = false

    ///
    public var chargeState: ChargeState = ChargeState()

    ///
    public var climateState: ClimateState = ClimateState()

    ///
    public var guiSettings: GUISettings = GUISettings()

    ///
    public var driveState: DriveState = DriveState()

    ///
    public var vehicleState: VehicleState = VehicleState()

    ///
    public var vehicleConfig: VehicleConfig = VehicleConfig()

    ///
    public init() {
        allValues = Map(mappingType: .fromJSON, JSON: ["":""])
    }

    ///
    public var timestamp: TimeInterval { return self.climateState.timestamp }

}

@available(macOS 13.1, *)
extension Vehicle: DataResponse {
    public mutating func mapping(map: Map) {
        allValues = map
        let isVehicleData: Bool = !(map.JSON["id_s"] is String)
        if isVehicleData {
            displayName <- map["response.display_name"]
            id <- map["response.id_s"]
            options <- (map["response.option_codes"], VehicleOptionTransform(separator: ","))
            userId <- map["response.user_id"]
            vehicleId <- map["response.vehicle_id"]
            vin <- (map["response.vin"], VINTransform())
            status <- (map["response.state"], EnumTransform())
            remoteStartEnabled <- map["response.remote_start_enabled"]
            tokens <- map["response.tokens"]
            chargeState <- map["response.charge_state"]
            climateState <- map["response.climate_state"]
            guiSettings <- map["response.gui_settings"]
            driveState <- map["response.drive_state"]
            vehicleState <- map["response.vehicle_state"]
            vehicleConfig <- map["response.vehicle_config"]
            inService <- map["response.in_service"]
        } else {
            displayName <- map["display_name"]
            id <- map["id_s"]
            options <- (map["option_codes"], VehicleOptionTransform(separator: ","))
            userId <- map["user_id"]
            vehicleId <- map["vehicle_id"]
            vin <- (map["vin"], VINTransform())
            status <- (map["state"], EnumTransform())
            remoteStartEnabled <- map["remote_start_enabled"]
            tokens <- map["tokens"]
        }
        var i = 0
		for entry in options {
            optionValues.append(VehicleAllData(entry.code, (entry.name + " " + entry.description), i % 2 == 0))
			i = i + 1
		}
    }
}

@available(macOS 13.1, *)
extension Vehicle: Equatable {
    public static func == (lhs: Vehicle, rhs: Vehicle) -> Bool {
        return lhs.chargeState.batteryLevel == rhs.chargeState.batteryLevel
            && lhs.chargeState.batteryRange == rhs.chargeState.batteryRange
    }
}

@available(macOS 13.1, *)
extension Vehicle {
    public var kindOfVehcile: KindOfVehicle {
        if id == "" {
            return KindOfVehicle.novehicle
        } else if self.id == "1" {
            return KindOfVehicle.demovehicle
        } else {
            return KindOfVehicle.ledgitVehicle
        }
    }
    
    public var batteryCapacity: Double {
        for code in self.options {
            switch code.code {
            case "BT37":
                return 75
            case "BT40":
                return 40
            case "BT60":
                return 60
            case "BT70":
                return 70
            case "BT85":
                return 85
            case "BTX4":
                return 90
            case "BTX5":
                return 75
            case "BTX6":
                return 100
            case "BTX7":
                return 75
            case "BTX8":
                return 85
            default: break
            }
        }
        return 75
    }
}

