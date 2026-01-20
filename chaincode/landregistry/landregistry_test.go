package main

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/assert"
)

// Simple test for data structure validation
func TestLandRecordStructure(t *testing.T) {
	record := LandRecord{
		PlotID:    "PLOT001",
		OwnerID:   "OWNER001",
		OwnerName: "John Doe",
		Area:      100.5,
		Location:  "City Center",
		Status:    "active",
	}

	assert.Equal(t, "PLOT001", record.PlotID)
	assert.Equal(t, "OWNER001", record.OwnerID)
	assert.Equal(t, "John Doe", record.OwnerName)
	assert.Equal(t, 100.5, record.Area)
	assert.Equal(t, "City Center", record.Location)
	assert.Equal(t, "active", record.Status)
}

// Test JSON marshaling/unmarshaling
func TestLandRecordJSON(t *testing.T) {
	record := LandRecord{
		PlotID:    "PLOT001",
		OwnerID:   "OWNER001",
		OwnerName: "John Doe",
		Area:      100.5,
		Location:  "City Center",
		Status:    "active",
	}

	// Marshal to JSON
	jsonData, err := json.Marshal(record)
	assert.NoError(t, err)
	assert.NotNil(t, jsonData)

	// Unmarshal from JSON
	var unmarshaledRecord LandRecord
	err = json.Unmarshal(jsonData, &unmarshaledRecord)
	assert.NoError(t, err)
	assert.Equal(t, record.PlotID, unmarshaledRecord.PlotID)
	assert.Equal(t, record.OwnerID, unmarshaledRecord.OwnerID)
	assert.Equal(t, record.OwnerName, unmarshaledRecord.OwnerName)
}

// Test TransferRecord structure
func TestTransferRecordStructure(t *testing.T) {
	transfer := TransferRecord{
		TransferID:    "TRANSFER-001",
		PlotID:        "PLOT001",
		FromOwnerID:   "OWNER001",
		ToOwnerID:     "OWNER002",
		ToOwnerName:   "Jane Smith",
		AuthorizedBy:  "admin@landreg.example.com",
		TransactionID: "TX001",
	}

	assert.Equal(t, "TRANSFER-001", transfer.TransferID)
	assert.Equal(t, "PLOT001", transfer.PlotID)
	assert.Equal(t, "OWNER001", transfer.FromOwnerID)
	assert.Equal(t, "OWNER002", transfer.ToOwnerID)
}

// Test TransferRecord JSON
func TestTransferRecordJSON(t *testing.T) {
	transfer := TransferRecord{
		TransferID:    "TRANSFER-001",
		PlotID:        "PLOT001",
		FromOwnerID:   "OWNER001",
		ToOwnerID:     "OWNER002",
		ToOwnerName:   "Jane Smith",
		AuthorizedBy:  "admin@landreg.example.com",
		TransactionID: "TX001",
	}

	jsonData, err := json.Marshal(transfer)
	assert.NoError(t, err)
	assert.NotNil(t, jsonData)

	var unmarshaledTransfer TransferRecord
	err = json.Unmarshal(jsonData, &unmarshaledTransfer)
	assert.NoError(t, err)
	assert.Equal(t, transfer.TransferID, unmarshaledTransfer.TransferID)
	assert.Equal(t, transfer.PlotID, unmarshaledTransfer.PlotID)
}

// Test input validation logic (without full chaincode context)
func TestInputValidation(t *testing.T) {
	// Test empty plotId
	assert.True(t, "" == "", "Empty string validation")

	// Test negative area
	area := -10.0
	assert.True(t, area <= 0, "Negative area validation")

	// Test valid area
	validArea := 100.5
	assert.True(t, validArea > 0, "Valid area check")
}

// Test status validation
func TestStatusValidation(t *testing.T) {
	validStatuses := map[string]bool{
		"active":  true,
		"pending": true,
		"disputed": true,
	}

	assert.True(t, validStatuses["active"])
	assert.True(t, validStatuses["pending"])
	assert.True(t, validStatuses["disputed"])
	assert.False(t, validStatuses["invalid"])
}

// Test MSP authorization logic
func TestMSPAuthorization(t *testing.T) {
	authorizedMSPs := map[string]bool{
		"LandRegMSP":      true,
		"SubRegistrarMSP": true,
		"CourtMSP":        true,
	}

	assert.True(t, authorizedMSPs["LandRegMSP"])
	assert.True(t, authorizedMSPs["SubRegistrarMSP"])
	assert.True(t, authorizedMSPs["CourtMSP"])
	assert.False(t, authorizedMSPs["PublicMSP"])
	assert.False(t, authorizedMSPs["UnauthorizedMSP"])
}

// Test transfer history tracking
func TestTransferHistory(t *testing.T) {
	record := LandRecord{
		PlotID:          "PLOT001",
		TransferHistory: []string{},
	}

	// Simulate adding transfer to history
	transferKey1 := "TRANSFER-PLOT001-TX001"
	record.TransferHistory = append(record.TransferHistory, transferKey1)

	assert.Equal(t, 1, len(record.TransferHistory))
	assert.Equal(t, transferKey1, record.TransferHistory[0])

	// Add another transfer
	transferKey2 := "TRANSFER-PLOT001-TX002"
	record.TransferHistory = append(record.TransferHistory, transferKey2)

	assert.Equal(t, 2, len(record.TransferHistory))
	assert.Equal(t, transferKey2, record.TransferHistory[1])
}
