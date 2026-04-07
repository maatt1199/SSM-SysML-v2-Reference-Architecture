package 'SysML v2 Examples' {
    doc/*Uses CATIA-specific imports. */
    private import DS_Views::**;
    private import SysML::*;
    private import ScalarValues::*;
    private import ISQ::*;
    private import SI::*;
    private import ModelingMetadata::*;
    package 'Figure 5 - Individual Modelling' {
        individual def Person;
        individual 'Person A' : Person;
        individual 'Person B' : Person;
        use case 'Use Case' {
            subject ;
            actor 'Use Case Actor' :> 'Person A';
        }
        use case 'Specialised Use Case' :> 'Use Case' {
            subject ;
            actor 'Use Case Actor' :>> 'Use Case'::'Use Case Actor' :> 'Person B';
        }
        concern Concern {
            subject ;
            stakeholder 'Concern Stakeholder' :> 'Person A';
        }
        view 'Individual Modelling' : gv {
            expose 'Figure 5 - Individual Modelling'::*;
        }
    }
    package 'Figure 6 - Use Case Modelling' {
        item def Water {
            attribute waterTemp : ISQThermodynamics::CelsiusTemperatureValue;
        }
        item def BoilSignal {
            attribute targetTemp : ISQThermodynamics::CelsiusTemperatureValue := 100;
        }
        part tap {
            out tapWater : Water;
        }
        flow of Water from tap.tapWater to 'Boil Water'.coldWater;
        part cup {
            in boiledWater : Water;
        }
        flow of Water from 'Boil Water'.boiledWater to cup.boiledWater;
        part 'Person A Kettle' {
            item kettleWater : Water;
            attribute 'Power Supply' : Boolean = false;
            part Button {
                attribute isOn : Boolean = false;
            }
            in coldWater :> tap.tapWater;
            out boiledWater :> kettleWater {
                attribute boiledTemp :>> waterTemp := 100;
            }
            exhibit state 'Kettle Power States' {
                entry ;
                then off;
                state off;
                state standby;
                state on;
                transition first off if 'Power Supply' == true then standby;
                transition first standby if 'Power Supply' == false then off;
                transition first on if 'Power Supply' == false then off;
                transition first standby if Button.isOn == true then on;
                transition first on accept BoilSignal then standby;
            }
        }
        individual 'Person A';
        concern 'Water Temperature' {
            subject water :> 'Person A Kettle'.kettleWater;
            stakeholder Stakeholder :> 'Person A';
        }
        requirement 'Boiling Water' {
            subject water :> 'Person A Kettle'.kettleWater;
            doc /* Water shall be heated to 100 C.*/
            frame 'Water Temperature';
            require constraint 'Temperature Goal' {
                water.waterTemp == 100
            }
        }
        use case 'Boil Water' {
            subject water :> 'Person A Kettle'.kettleWater;
            objective {
                require 'Boiling Water';
            }
            actor Human :> 'Person A' {
                perform fillKettle;
                perform turnOn;
                perform pressButton;
                perform turnOff;
                perform fillCup;
            }
            actor Kettle :> 'Person A Kettle' {
                perform boilWater;
            }
            in coldWater : Water;
            out boiledWater : Water;
            action fillKettle {
                in item waterIn : Water;
                out item waterOut : Water;
            }
            action turnOn {
                action assign Kettle.'Power Supply' := true;
            }
            action pressButton {
                action assign Kettle.Button.isOn := true;
            }
            action boilWater {
                action send new BoilSignal() to Kettle;
            }
            action turnOff {
                action assign Kettle.'Power Supply' := false;
            }
            action fillCup {
                in item waterIn : Water;
                out item waterOut : Water;
            }
            first start then fillKettle;
            first fillKettle then turnOn;
            first turnOn then pressButton;
            first pressButton then boilWater;
            first boilWater then turnOff;
            first turnOff then fillCup;
            first fillCup then done;
            flow of Water from coldWater to fillKettle.waterIn;
            flow of Water from fillKettle.waterOut to fillCup.waterIn;
            flow of Water from fillCup.waterOut to boiledWater;
        }
        view 'Use Case Modelling' : gv {
            expose 'Figure 6 - Use Case Modelling'::*;
        }
        flow of Water from 'Person A Kettle'.coldWater to 'Person A Kettle'.boiledWater;
    }
    package 'Figure 7 - Metadata Modelling' {
        metadata def 'New Metadata' {
            attribute Description : String;
        }
        part Part {
            @'New Metadata' { :>> Description = "Information concerning New Metadata."; }
            @Rationale { :>> text = "Rationale details."; }
        }
        enum def Elements {
            Customer;
            Actor;
            Transformation;
            Worldview;
            Owner;
            Environment;
        }
        metadata def CATWOE {
            attribute 'CATWOE Element' : Elements [1..*];
        }
        view 'Metadata Modelling' : gv {
            expose 'Figure 7 - Metadata Modelling'::*;
        }
    }
}
