package SSMCaseStudy {
    library package 'CATWOE Library' {
        private import StakeholderContext::SC_Defs::Role;
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
    }
    package StakeholderContext {
        package SC_Defs {
            private import ScalarValues::*;
            private import 'CATWOE Library'::*;
            individual def Employee {
                attribute name : String;
            }
            concern def OwnerConcern {
                @CATWOE { :>> 'CATWOE Element' = Elements::Owner; }
            }
            part def Role {
                ref part assignedEmployee : Employee;
                ref part requiredTool : Tool;
            }
            part def Tool {
                attribute toolName : String;
                ref part license : License [0..1];
                exhibit state licenseState {
                    state capacityAvailable;
                    state capacityUnavailable;
                    transition first capacityAvailable if license.available <= 0 then capacityUnavailable;
                    transition first capacityUnavailable if license.available > 0 then capacityAvailable;
                }
            }
            part def License {
                attribute capacity : Integer;
                attribute allocated : Integer;
                derived attribute available : Integer = capacity - allocated;
            }
            requirement def EnvironmentalConstraints {
                @CATWOE { :>> 'CATWOE Element' = Elements::Environment; }
            }
            requirement def EC1 :> EnvironmentalConstraints {
                doc /* New hires shall be given access to tool necessary to perform their Job Role.*/
                subject role : Role;
            }
            requirement def EC2 :> EnvironmentalConstraints {
                doc /* New hires shall be given access to a tool only when there is availability.*/
                subject toollicense : License;
                require constraint {
                    toollicense.available > 0
                }
            }
            #ModelingMetadata::refinement dependency <refinement> from EC2 to EC1;
        }
        package SC_Usages {
            private import SC_Defs::*;
            private import 'CATWOE Library'::*;
            individual newHire : Employee {
                attribute :>> Employee::name = "New Hire";
            }
            individual manager : Employee {
                @CATWOE { :>> 'CATWOE Element' = (Elements::Customer, Elements::Actor); }
                attribute :>> Employee::name = "Manager";
            }
            individual it : Employee {
                @CATWOE { :>> 'CATWOE Element' = (Elements::Actor, Elements::Owner); }
                attribute :>> Employee::name = "IT";
            }
            concern resources : OwnerConcern {
                subject license : License;
                binding bind license = licenseA;
                stakeholder :> it;
            }
            part toolA : Tool {
                attribute :>> toolName = "ToolA";
                ref part license :>> license;
                binding bind license = licenseA;
            }
            part licenseA : License {
                attribute :>> capacity = 100;
                attribute :>> allocated = 10;
            }
            part roleA : Role {
                satisfy ec1;
                ref part requiredToolA :>> requiredTool = toolA;
            }
            requirement ec1 : EC1 {
                doc /* New hires in Role A shall be assigned the apropriate tools and license.*/
                subject role = roleA;
            }
            requirement ec2 : EC2 {
                doc /* New hires in Role A shall be assigned a license to Tool A only when there is available capacity.*/
                subject toollicense = licenseA;
            }
        }
    }
    package ArchitectureViewpoints {
        private import 'CATWOE Library'::*;
        private import SysML::**;
        private import StakeholderContext::**;
        private import ModelingMetadata::*;
        package AV_Defs {
            viewpoint def ResourceAllocation {
                @CATWOE { :>> 'CATWOE Element' = Elements::Worldview; }
            }
            view def LicenseAllocation {
                doc /* Allocation of Tool Licenses as per Job Role.*/
            }
            use case def CATWOE_Transformation {
                @CATWOE { :>> 'CATWOE Element' = Elements::Transformation; }
                doc /* Specify Transformation details here.*/
                subject transformationSubject;
            }
            use case def AssignLicense :> CATWOE_Transformation {
                doc /* Assign an available License to New Employees for the correct Tool based on their Role.*/
                subject newEmployeeRole : Role :>> transformationSubject;
            }
        }
        package AV_Usages {
            private import AV_Defs::*;
            viewpoint licenseManagement : ResourceAllocation {
                @Rationale { :>> text = "Appropriate access should be given to new hires and license availability recorded."; }
                frame resources;
            }
            view licenseA_Allocation : LicenseAllocation {
                doc /* Allocation of Tool A License as per Job Role A.*/
                satisfy licenseManagement;
            }
        }
    }
    package ArchitectureDescriptions {
        private import 'CATWOE Library'::*;
        private import ArchitectureViewpoints::**;
        private import StakeholderContext::**;
        part transformationSystem {
            @CATWOE { :>> 'CATWOE Element' = Elements::Transformation; }
            part roleA_NewHire :> roleA {
                doc /* This is the usage of Role A which will be occupied by New Hire, and is the subject of the transformation.*/
                ref part employee :>> assignedEmployee;
                binding bind employee = SC_Usages::newHire;
            }
            item def AccessRequest {
                ref part requestedRole : Role;
            }
            item def UnavailableNotice;
            use case assignLicenseA : AssignLicense {
                subject :>> newEmployeeRole : Role = roleA_NewHire;
                objective {
                    doc /* Allocation of a license for Tool A to New Hire. */
                    require ec2;
                }
                actor manager = SC_Usages::manager {
                    perform reviewAndRequest;
                    perform rejectionReception;
                }
                actor it = SC_Usages::it {
                    perform evaluateAvailability;
                    perform informUnavailable;
                    perform provisionAccess;
                }
                binding bind it = SC_Usages::it;
                ref part targetRole :> roleA_NewHire;
                ref part targetLicense :> roleA_NewHire.requiredToolA.license;
                action reviewAndRequest {
                    in newHireIn : Role;
                    out request : AccessRequest {
                        ref part :>> requestedRole = targetRole;
                    }
                }
                action evaluateAvailability { in incomingRequest : AccessRequest; }
                action informUnavailable { out notice : UnavailableNotice; }
                action provisionAccess {
                    satisfy ec2 by licenseIn;
                    in licenseIn : License;
                    out licenseOut : License;
                    action assign licenseOut.allocated := licenseIn.allocated + 1;
                }
                action rejectionReception { in notice : UnavailableNotice; }
                first start then reviewAndRequest;
                flow of AccessRequest from reviewAndRequest.request to evaluateAvailability.incomingRequest;
                first reviewAndRequest then evaluateAvailability;
                first evaluateAvailability;
                then decide AvailabilityDecision;
                if evaluateAvailability.incomingRequest.requestedRole.requiredTool.license.available > 0 then provisionAccess;
                if evaluateAvailability.incomingRequest.requestedRole.requiredTool.license.available <= 0 then informUnavailable;
                flow of UnavailableNotice from informUnavailable.notice to rejectionReception.notice;
                first rejectionReception then done;
                first provisionAccess then done;
                binding bind provisionAccess.licenseIn = targetLicense;
                binding bind provisionAccess.licenseIn = SC_Usages::licenseA;
                binding bind provisionAccess.licenseOut = targetLicense;
                binding bind targetRole = reviewAndRequest.newHireIn;
                first evaluateAvailability then AvailabilityDecision;
            }
        }
    }
    private import DS_Views::**;
    view CaseStudy : DS_Views::SymbolicViews::gv;
    view IndividualModelling : DS_Views::SymbolicViews::gv;
    view Definition : gv;
    view Usage : gv;
    view VPs : gv;
    binding bind StakeholderContext::SC_Usages::roleA = StakeholderContext::SC_Usages::ec1.role;
    binding bind StakeholderContext::SC_Usages::ec2.toollicense = StakeholderContext::SC_Usages::licenseA;
    binding bind StakeholderContext::SC_Usages::roleA.requiredToolA = StakeholderContext::SC_Usages::toolA;
}
package Presentation {
    private import SSMCaseStudy::**;
    private import DS_Views::**;
    view Fig5 : gv;
    view EC2Example : gv;
}
