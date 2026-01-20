package main

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// LandRegistryContract provides functions for managing land records
type LandRegistryContract struct {
	contractapi.Contract
}

// LandRecord represents a land ownership record
type LandRecord struct {
	PlotID          string   `json:"plotId"`
	OwnerID         string   `json:"ownerId"`
	OwnerName       string   `json:"ownerName"`
	Area            float64  `json:"area"`
	Location        string   `json:"location"`
	Timestamp       string   `json:"timestamp"`
	PreviousOwnerID string   `json:"previousOwnerId"`
	TransferHistory []string `json:"transferHistory"`
	Status          string   `json:"status"` // "active", "pending", "disputed"
	CreatedBy       string   `json:"createdBy"`
	LastModifiedBy  string   `json:"lastModifiedBy"`
}

// TransferRecord represents a single transfer transaction
type TransferRecord struct {
	TransferID    string `json:"transferId"`
	PlotID        string `json:"plotId"`
	FromOwnerID   string `json:"fromOwnerId"`
	ToOwnerID     string `json:"toOwnerId"`
	ToOwnerName   string `json:"toOwnerName"`
	Timestamp     string `json:"timestamp"`
	AuthorizedBy  string `json:"authorizedBy"`
	TransactionID string `json:"transactionId"`
}

// CreateLandRecord creates a new land record
// Only authorized government organizations can create records
func (s *LandRegistryContract) CreateLandRecord(ctx contractapi.TransactionContextInterface, plotId string, ownerId string, ownerName string, area float64, location string) error {
	// Check if caller is authorized (must be from authorized organization)
	err := s.verifyAuthorizedCaller(ctx)
	if err != nil {
		return fmt.Errorf("unauthorized: %v", err)
	}

	// Validate inputs
	if plotId == "" {
		return fmt.Errorf("plotId cannot be empty")
	}
	if ownerId == "" {
		return fmt.Errorf("ownerId cannot be empty")
	}
	if ownerName == "" {
		return fmt.Errorf("ownerName cannot be empty")
	}
	if area <= 0 {
		return fmt.Errorf("area must be greater than 0")
	}
	if location == "" {
		return fmt.Errorf("location cannot be empty")
	}

	// Check if land record already exists
	existingRecord, err := ctx.GetStub().GetState(plotId)
	if err != nil {
		return fmt.Errorf("failed to read from world state: %v", err)
	}
	if existingRecord != nil {
		return fmt.Errorf("land record with plotId %s already exists", plotId)
	}

	// Get caller identity
	callerID, err := s.getCallerID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Create new land record
	landRecord := LandRecord{
		PlotID:          plotId,
		OwnerID:         ownerId,
		OwnerName:       ownerName,
		Area:            area,
		Location:        location,
		Timestamp:       time.Now().UTC().Format(time.RFC3339),
		PreviousOwnerID: "",
		TransferHistory: []string{},
		Status:          "active",
		CreatedBy:       callerID,
		LastModifiedBy:  callerID,
	}

	// Convert to JSON
	landRecordJSON, err := json.Marshal(landRecord)
	if err != nil {
		return fmt.Errorf("failed to marshal land record: %v", err)
	}

	// Save to world state
	err = ctx.GetStub().PutState(plotId, landRecordJSON)
	if err != nil {
		return fmt.Errorf("failed to put land record to world state: %v", err)
	}

	return nil
}

// TransferLand transfers ownership of a land parcel
// Only authorized government organizations can transfer ownership
func (s *LandRegistryContract) TransferLand(ctx contractapi.TransactionContextInterface, plotId string, newOwnerId string, newOwnerName string) error {
	// Check if caller is authorized
	err := s.verifyAuthorizedCaller(ctx)
	if err != nil {
		return fmt.Errorf("unauthorized: %v", err)
	}

	// Validate inputs
	if plotId == "" {
		return fmt.Errorf("plotId cannot be empty")
	}
	if newOwnerId == "" {
		return fmt.Errorf("newOwnerId cannot be empty")
	}
	if newOwnerName == "" {
		return fmt.Errorf("newOwnerName cannot be empty")
	}

	// Get existing land record
	landRecordJSON, err := ctx.GetStub().GetState(plotId)
	if err != nil {
		return fmt.Errorf("failed to read from world state: %v", err)
	}
	if landRecordJSON == nil {
		return fmt.Errorf("land record with plotId %s does not exist", plotId)
	}

	// Unmarshal existing record
	var landRecord LandRecord
	err = json.Unmarshal(landRecordJSON, &landRecord)
	if err != nil {
		return fmt.Errorf("failed to unmarshal land record: %v", err)
	}

	// Check if land is transferable
	if landRecord.Status == "disputed" {
		return fmt.Errorf("cannot transfer land with disputed status")
	}
	if landRecord.Status == "pending" {
		return fmt.Errorf("cannot transfer land with pending status")
	}

	// Check if transferring to same owner
	if landRecord.OwnerID == newOwnerId {
		return fmt.Errorf("cannot transfer to the same owner")
	}

	// Get caller identity
	callerID, err := s.getCallerID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Get transaction ID
	txID := ctx.GetStub().GetTxID()

	// Create transfer record
	transferRecord := TransferRecord{
		TransferID:    fmt.Sprintf("TRANSFER-%s-%d", plotId, time.Now().Unix()),
		PlotID:        plotId,
		FromOwnerID:   landRecord.OwnerID,
		ToOwnerID:     newOwnerId,
		ToOwnerName:   newOwnerName,
		Timestamp:     time.Now().UTC().Format(time.RFC3339),
		AuthorizedBy:  callerID,
		TransactionID: txID,
	}

	// Save transfer record
	transferRecordJSON, err := json.Marshal(transferRecord)
	if err != nil {
		return fmt.Errorf("failed to marshal transfer record: %v", err)
	}

	transferKey := fmt.Sprintf("TRANSFER-%s-%s", plotId, txID)
	err = ctx.GetStub().PutState(transferKey, transferRecordJSON)
	if err != nil {
		return fmt.Errorf("failed to put transfer record to world state: %v", err)
	}

	// Update land record
	landRecord.PreviousOwnerID = landRecord.OwnerID
	landRecord.OwnerID = newOwnerId
	landRecord.OwnerName = newOwnerName
	landRecord.Timestamp = time.Now().UTC().Format(time.RFC3339)
	landRecord.LastModifiedBy = callerID
	landRecord.TransferHistory = append(landRecord.TransferHistory, transferKey)

	// Save updated land record
	updatedRecordJSON, err := json.Marshal(landRecord)
	if err != nil {
		return fmt.Errorf("failed to marshal updated land record: %v", err)
	}

	err = ctx.GetStub().PutState(plotId, updatedRecordJSON)
	if err != nil {
		return fmt.Errorf("failed to put updated land record to world state: %v", err)
	}

	return nil
}

// QueryLandRecord queries a land record by plotId
// Public function - anyone can query
func (s *LandRegistryContract) QueryLandRecord(ctx contractapi.TransactionContextInterface, plotId string) (*LandRecord, error) {
	if plotId == "" {
		return nil, fmt.Errorf("plotId cannot be empty")
	}

	landRecordJSON, err := ctx.GetStub().GetState(plotId)
	if err != nil {
		return nil, fmt.Errorf("failed to read from world state: %v", err)
	}
	if landRecordJSON == nil {
		return nil, fmt.Errorf("land record with plotId %s does not exist", plotId)
	}

	var landRecord LandRecord
	err = json.Unmarshal(landRecordJSON, &landRecord)
	if err != nil {
		return nil, fmt.Errorf("failed to unmarshal land record: %v", err)
	}

	return &landRecord, nil
}

// QueryLandHistory queries the complete ownership history of a land parcel
// Public function - anyone can query
func (s *LandRegistryContract) QueryLandHistory(ctx contractapi.TransactionContextInterface, plotId string) ([]*TransferRecord, error) {
	if plotId == "" {
		return nil, fmt.Errorf("plotId cannot be empty")
	}

	// Get all transfer records for this plot
	historyIterator, err := ctx.GetStub().GetHistoryForKey(plotId)
	if err != nil {
		return nil, fmt.Errorf("failed to get history for plotId %s: %v", plotId, err)
	}
	defer historyIterator.Close()

	var history []*TransferRecord
	for historyIterator.HasNext() {
		historyResponse, err := historyIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to get next history entry: %v", err)
		}

		// Parse the land record to extract transfer information
		var landRecord LandRecord
		err = json.Unmarshal(historyResponse.Value, &landRecord)
		if err != nil {
			continue // Skip invalid entries
		}

		// Get transfer records from transfer history
		for _, transferKey := range landRecord.TransferHistory {
			transferJSON, err := ctx.GetStub().GetState(transferKey)
			if err == nil && transferJSON != nil {
				var transfer TransferRecord
				err = json.Unmarshal(transferJSON, &transfer)
				if err == nil {
					history = append(history, &transfer)
				}
			}
		}
	}

	// Also query transfer records directly
	transferIterator, err := ctx.GetStub().GetStateByRange(fmt.Sprintf("TRANSFER-%s-", plotId), fmt.Sprintf("TRANSFER-%s-~", plotId))
	if err != nil {
		return nil, fmt.Errorf("failed to get transfer records: %v", err)
	}
	defer transferIterator.Close()

	transferMap := make(map[string]*TransferRecord)
	for transferIterator.HasNext() {
		queryResponse, err := transferIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to get next transfer record: %v", err)
		}

		var transfer TransferRecord
		err = json.Unmarshal(queryResponse.Value, &transfer)
		if err == nil {
			transferMap[transfer.TransferID] = &transfer
		}
	}

	// Convert map to slice
	var transferHistory []*TransferRecord
	for _, transfer := range transferMap {
		transferHistory = append(transferHistory, transfer)
	}

	return transferHistory, nil
}

// GetAllLandRecords returns all land records
// Only authorized organizations can query all records
func (s *LandRegistryContract) GetAllLandRecords(ctx contractapi.TransactionContextInterface) ([]*LandRecord, error) {
	// Check if caller is authorized
	err := s.verifyAuthorizedCaller(ctx)
	if err != nil {
		return nil, fmt.Errorf("unauthorized: %v", err)
	}

	// Query all records (using empty range to get all)
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, fmt.Errorf("failed to get state by range: %v", err)
	}
	defer resultsIterator.Close()

	var landRecords []*LandRecord
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, fmt.Errorf("failed to get next record: %v", err)
		}

		// Skip transfer records (they start with "TRANSFER-")
		if len(queryResponse.Key) > 8 && queryResponse.Key[:8] == "TRANSFER" {
			continue
		}

		var landRecord LandRecord
		err = json.Unmarshal(queryResponse.Value, &landRecord)
		if err != nil {
			continue // Skip invalid records
		}

		landRecords = append(landRecords, &landRecord)
	}

	return landRecords, nil
}

// UpdateLandStatus updates the status of a land record
// Only authorized organizations can update status
func (s *LandRegistryContract) UpdateLandStatus(ctx contractapi.TransactionContextInterface, plotId string, status string) error {
	// Check if caller is authorized
	err := s.verifyAuthorizedCaller(ctx)
	if err != nil {
		return fmt.Errorf("unauthorized: %v", err)
	}

	// Validate inputs
	if plotId == "" {
		return fmt.Errorf("plotId cannot be empty")
	}
	if status == "" {
		return fmt.Errorf("status cannot be empty")
	}

	// Validate status value
	validStatuses := map[string]bool{
		"active":  true,
		"pending": true,
		"disputed": true,
	}
	if !validStatuses[status] {
		return fmt.Errorf("invalid status: %s. Valid statuses are: active, pending, disputed", status)
	}

	// Get existing land record
	landRecordJSON, err := ctx.GetStub().GetState(plotId)
	if err != nil {
		return fmt.Errorf("failed to read from world state: %v", err)
	}
	if landRecordJSON == nil {
		return fmt.Errorf("land record with plotId %s does not exist", plotId)
	}

	// Unmarshal existing record
	var landRecord LandRecord
	err = json.Unmarshal(landRecordJSON, &landRecord)
	if err != nil {
		return fmt.Errorf("failed to unmarshal land record: %v", err)
	}

	// Get caller identity
	callerID, err := s.getCallerID(ctx)
	if err != nil {
		return fmt.Errorf("failed to get caller identity: %v", err)
	}

	// Update status
	landRecord.Status = status
	landRecord.LastModifiedBy = callerID
	landRecord.Timestamp = time.Now().UTC().Format(time.RFC3339)

	// Save updated record
	updatedRecordJSON, err := json.Marshal(landRecord)
	if err != nil {
		return fmt.Errorf("failed to marshal updated land record: %v", err)
	}

	err = ctx.GetStub().PutState(plotId, updatedRecordJSON)
	if err != nil {
		return fmt.Errorf("failed to put updated land record to world state: %v", err)
	}

	return nil
}

// verifyAuthorizedCaller checks if the caller belongs to an authorized organization
func (s *LandRegistryContract) verifyAuthorizedCaller(ctx contractapi.TransactionContextInterface) error {
	clientMSPID, err := ctx.GetClientIdentity().GetMSPID()
	if err != nil {
		return fmt.Errorf("failed to get MSP ID: %v", err)
	}

	// Authorized MSPs: LandRegMSP, SubRegistrarMSP, CourtMSP
	authorizedMSPs := map[string]bool{
		"LandRegMSP":      true,
		"SubRegistrarMSP": true,
		"CourtMSP":        true,
	}

	if !authorizedMSPs[clientMSPID] {
		return fmt.Errorf("caller with MSP ID %s is not authorized", clientMSPID)
	}

	return nil
}

// getCallerID gets the caller's identity ID
func (s *LandRegistryContract) getCallerID(ctx contractapi.TransactionContextInterface) (string, error) {
	callerID, err := ctx.GetClientIdentity().GetID()
	if err != nil {
		return "", fmt.Errorf("failed to get caller ID: %v", err)
	}
	return callerID, nil
}

func main() {
	landRegistryContract, err := contractapi.NewChaincode(&LandRegistryContract{})
	if err != nil {
		fmt.Printf("Error creating land registry chaincode: %v", err)
		return
	}

	if err := landRegistryContract.Start(); err != nil {
		fmt.Printf("Error starting land registry chaincode: %v", err)
	}
}
