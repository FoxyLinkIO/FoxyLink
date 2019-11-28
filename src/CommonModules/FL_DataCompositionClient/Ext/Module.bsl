////////////////////////////////////////////////////////////////////////////////
// This file is part of FoxyLink.
// Copyright © 2016-2019 Petro Bazeliuk.
// 
// This program is free software: you can redistribute it and/or modify 
// it under the terms of the GNU Affero General Public License as 
// published by the Free Software Foundation, either version 3 of the License,
// or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful, 
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the 
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License 
// along with FoxyLink. If not, see <http://www.gnu.org/licenses/agpl-3.0>.
//
////////////////////////////////////////////////////////////////////////////////

#Region ProgramInterface

// Runs data composition schema wizard for editing data composition schema.
//
// Parameters:
//  ManagedForm                  - ManagedForm - managed form.
//  DataCompositionSchemaAddress - String      - the address to read data composition schema.
//
Procedure RunDataCompositionSchemaWizard(ManagedForm, 
    DataCompositionSchemaAddress) Export
    
    #If ThickClientOrdinaryApplication OR ThickClientManagedApplication OR ТолстыйКлиентОбычноеПриложение OR ТолстыйКлиентУправляемоеПриложение Then
        
        // Copy existing data composition schema.
        DataCompositionSchema = XDTOSerializer.ReadXDTO(XDTOSerializer.WriteXDTO(
            GetFromTempStorage(DataCompositionSchemaAddress)));
        
        Wizard = New DataCompositionSchemaWizard(DataCompositionSchema);
        Wizard.Edit(ManagedForm);
        
    #Else
        
        ShowMessageBox(Undefined,
            NStr("en='To edit the layout scheme, run configuration in thick client mode.';
                |ru='Для того, чтобы редактировать схему компоновки, необходимо запустить конфигурацию в режиме толстого клиента.';
                |uk='Для того, щоб редагувати схему компонування, необхідно запустити конфігурацію в режимі товстого клієнта.';
                |en_CA='To edit the layout scheme, run configuration in thick client mode.'"));
        
    #EndIf
    
EndProcedure // RunDataCompositionSchemaWizard()

#EndRegion // ProgramInterface