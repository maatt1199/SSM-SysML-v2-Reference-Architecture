package ReferenceArchitecture {
    doc /*Uses CATIA-specific imports.*/
    private import ReferenceArchitecture::**;
    private import SysML::**;
    private import ScalarValues::*;
    private import ModelingMetadata::*;
    library package Metadata_Defs {
        enum def Elements {
            Customer;
            Actor;
            Transformation;
            Worldview;
            Owner;
            Environment;
        }
        metadata def CATWOE {
            attribute 'CATWOE Element' : Elements;
        }
    }
    package StakeholderContext {
        package SC_Defs {
            individual def Individual;
            concern def CustomerConcern {
                @CATWOE { :>> 'CATWOE Element' = Elements::Customer; }
            }
            concern def OwnerConcern {
                @CATWOE { :>> 'CATWOE Element' = Elements::Owner; }
            }
            requirement def EnvironmentalConstraints {
                @CATWOE { :>> 'CATWOE Element' = Elements::Environment; }
            }
            requirement def EC_Definition :> EnvironmentalConstraints {
                doc /* Requirement definition.*/
            }
        }
        package SC_Usages {
            individual usage_Customer : Individual {
                @CATWOE { :>> 'CATWOE Element' = Elements::Customer; }
            }
            individual usage_Actor : Individual {
                @CATWOE { :>> 'CATWOE Element' = Elements::Actor; }
            }
            individual usage_Owner : Individual {
                @CATWOE { :>> 'CATWOE Element' = Elements::Owner; }
            }
            concern usage_CC : CustomerConcern {
                subject :> transformationSubject;
                stakeholder :> usage_Customer;
            }
            concern usage_OC : OwnerConcern {
                subject :> transformationSubject;
                stakeholder :> usage_Owner;
            }
            requirement usage_EC : EC_Definition {
                doc /* Usage-specific requirement.*/
            }
        }
    }
    package ArchitectureViewpoints {
        package AV_Defs {
            use case def CATWOE_Transformation {
                @CATWOE { :>> 'CATWOE Element' = Elements::Transformation; }
            }
            use case def UC_Def :> CATWOE_Transformation {
                doc /* Specific Transformation process. */
            }
            viewpoint def Viewpoint_1 {
                @CATWOE { :>> 'CATWOE Element' = Elements::Worldview; }
                @Rationale { :>> SysML::Systems::RequirementUsage::text = "Elaborate here"; }
                doc /* Select relevant concern to frame.*/
                frame usage_OC;
                frame usage_CC;
            }
        }
        package AV_Usages {
            viewpoint usageVP1 : Viewpoint_1;
            view viewUsage {
                satisfy usageVP1;
            }
        }
    }
    package ArchitectureModels {
        part transformationSystem {
            @CATWOE { :>> 'CATWOE Element' = Elements::Transformation; }
            item Trigger;
            part transformationSubject {
                attribute guard : Boolean {
                    doc /* Illustrative boolean guard. */
                }
                attribute Value : Real;
                exhibit state Subject_States {
                    in receiveTrigger : Trigger;
                    state state1;
                    state state2;
                    transition first state1 accept receiveTrigger if guard == true then state2;
                }
            }
            use case transformationProcess {
                subject usecaseSubject :> transformationSubject;
                actor Actor :> usage_Actor {
                    perform sendMessage;
                }
                action sendMessage { out sendTrigger : Trigger; }
                action assignValue {
                    action assign usecaseSubject.Value := 1;
                    doc /* Illustrative example of assigning a value. */
                }
            }
            flow of Trigger from transformationProcess.sendMessage.sendTrigger to transformationSubject.Subject_States.receiveTrigger;
        }
    }
    view TemplateView : DS_Views::SymbolicViews::gv;
}
