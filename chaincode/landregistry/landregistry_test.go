package main

import (
	"encoding/json"
	"testing"

	"github.com/hyperledger/fabric-contract-api-go/contractapi"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// MockTransactionContext provides a mock implementation of TransactionContextInterface
type MockTransactionContext struct {
	mock.Mock
	contractapi.TransactionContextInterface
}

// MockStub provides a mock implementation of ChaincodeStubInterface
type MockStub struct {
	mock.Mock
	contractapi.ChaincodeStubInterface
	State map[string][]byte
}

func NewMockStub() *MockStub {
	return &MockStub{
		State: make(map[string][]byte),
	}
}

func (ms *MockStub) GetState(key string) ([]byte, error) {
	args := ms.Called(key)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).([]byte), args.Error(1)
}

func (ms *MockStub) PutState(key string, value []byte) error {
	ms.State[key] = value
	args := ms.Called(key, value)
	return args.Error(0)
}

func (ms *MockStub) DelState(key string) error {
	delete(ms.State, key)
	args := ms.Called(key)
	return args.Error(0)
}

func (ms *MockStub) GetStateByRange(startKey, endKey string) (contractapi.StateQueryIteratorInterface, error) {
	args := ms.Called(startKey, endKey)
	return args.Get(0).(contractapi.StateQueryIteratorInterface), args.Error(1)
}

func (ms *MockStub) GetHistoryForKey(key string) (contractapi.HistoryQueryIteratorInterface, error) {
	args := ms.Called(key)
	return args.Get(0).(contractapi.HistoryQueryIteratorInterface), args.Error(1)
}

func (ms *MockStub) GetTxID() string {
	args := ms.Called()
	return args.String(0)
}

// MockClientIdentity provides a mock implementation of ClientIdentityInterface
type MockClientIdentity struct {
	mock.Mock
	contractapi.ClientIdentityInterface
	MSPID string
	ID    string
}

func (mci *MockClientIdentity) GetMSPID() (string, error) {
	return mci.MSPID, nil
}

func (mci *MockClientIdentity) GetID() (string, error) {
	return mci.ID, nil
}

// MockTransactionContext implementation
type MockTransactionContextImpl struct {
	Stub         *MockStub
	ClientID     *MockClientIdentity
	contractapi.TransactionContextInterface
}

func (mtc *MockTransactionContextImpl) GetStub() contractapi.ChaincodeStubInterface {
	return mtc.Stub
}

func (mtc *MockTransactionContextImpl) GetClientIdentity() contractapi.ClientIdentityInterface {
	return mtc.ClientID
}

// Test CreateLandRecord
func TestCreateLandRecord(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "LandRegMSP",
			ID:    "admin@landreg.example.com",
		},
	}

	// Mock GetState to return nil (record doesn't exist)
	ctx.Stub.On("GetState", "PLOT001").Return(nil, nil)
	ctx.Stub.On("PutState", "PLOT001", mock.Anything).Return(nil)

	err := contract.CreateLandRecord(ctx, "PLOT001", "OWNER001", "John Doe", 100.5, "City Center")
	assert.NoError(t, err)
	ctx.Stub.AssertExpectations(t)
}

// Test CreateLandRecord with empty plotId
func TestCreateLandRecordEmptyPlotId(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "LandRegMSP",
			ID:    "admin@landreg.example.com",
		},
	}

	err := contract.CreateLandRecord(ctx, "", "OWNER001", "John Doe", 100.5, "City Center")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "plotId cannot be empty")
}

// Test CreateLandRecord with invalid area
func TestCreateLandRecordInvalidArea(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "LandRegMSP",
			ID:    "admin@landreg.example.com",
		},
	}

	err := contract.CreateLandRecord(ctx, "PLOT001", "OWNER001", "John Doe", -10, "City Center")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "area must be greater than 0")
}

// Test CreateLandRecord unauthorized
func TestCreateLandRecordUnauthorized(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "PublicMSP", // Unauthorized MSP
			ID:    "public@example.com",
		},
	}

	err := contract.CreateLandRecord(ctx, "PLOT001", "OWNER001", "John Doe", 100.5, "City Center")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "unauthorized")
}

// Test QueryLandRecord
func TestQueryLandRecord(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "LandRegMSP",
			ID:    "admin@landreg.example.com",
		},
	}

	// Create a test land record
	landRecord := LandRecord{
		PlotID:    "PLOT001",
		OwnerID:   "OWNER001",
		OwnerName: "John Doe",
		Area:      100.5,
		Location:  "City Center",
		Status:    "active",
	}

	landRecordJSON, _ := json.Marshal(landRecord)
	ctx.Stub.On("GetState", "PLOT001").Return(landRecordJSON, nil)

	result, err := contract.QueryLandRecord(ctx, "PLOT001")
	assert.NoError(t, err)
	assert.NotNil(t, result)
	assert.Equal(t, "PLOT001", result.PlotID)
	assert.Equal(t, "OWNER001", result.OwnerID)
	assert.Equal(t, "John Doe", result.OwnerName)
}

// Test TransferLand
func TestTransferLand(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "LandRegMSP",
			ID:    "admin@landreg.example.com",
		},
	}

	// Create existing land record
	existingRecord := LandRecord{
		PlotID:    "PLOT001",
		OwnerID:   "OWNER001",
		OwnerName: "John Doe",
		Area:      100.5,
		Location:  "City Center",
		Status:    "active",
	}

	existingRecordJSON, _ := json.Marshal(existingRecord)
	ctx.Stub.On("GetState", "PLOT001").Return(existingRecordJSON, nil)
	ctx.Stub.On("GetTxID").Return("TX001")
	ctx.Stub.On("PutState", mock.Anything, mock.Anything).Return(nil).Times(2) // Transfer record + updated land record

	err := contract.TransferLand(ctx, "PLOT001", "OWNER002", "Jane Smith")
	assert.NoError(t, err)
}

// Test TransferLand with disputed status
func TestTransferLandDisputed(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "LandRegMSP",
			ID:    "admin@landreg.example.com",
		},
	}

	// Create existing land record with disputed status
	existingRecord := LandRecord{
		PlotID:    "PLOT001",
		OwnerID:   "OWNER001",
		OwnerName: "John Doe",
		Area:      100.5,
		Location:  "City Center",
		Status:    "disputed",
	}

	existingRecordJSON, _ := json.Marshal(existingRecord)
	ctx.Stub.On("GetState", "PLOT001").Return(existingRecordJSON, nil)

	err := contract.TransferLand(ctx, "PLOT001", "OWNER002", "Jane Smith")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "cannot transfer land with disputed status")
}

// Test UpdateLandStatus
func TestUpdateLandStatus(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "CourtMSP",
			ID:    "judge@court.example.com",
		},
	}

	// Create existing land record
	existingRecord := LandRecord{
		PlotID:    "PLOT001",
		OwnerID:   "OWNER001",
		OwnerName: "John Doe",
		Area:      100.5,
		Location:  "City Center",
		Status:    "active",
	}

	existingRecordJSON, _ := json.Marshal(existingRecord)
	ctx.Stub.On("GetState", "PLOT001").Return(existingRecordJSON, nil)
	ctx.Stub.On("PutState", "PLOT001", mock.Anything).Return(nil)

	err := contract.UpdateLandStatus(ctx, "PLOT001", "disputed")
	assert.NoError(t, err)
}

// Test UpdateLandStatus with invalid status
func TestUpdateLandStatusInvalid(t *testing.T) {
	contract := new(LandRegistryContract)
	ctx := &MockTransactionContextImpl{
		Stub: NewMockStub(),
		ClientID: &MockClientIdentity{
			MSPID: "CourtMSP",
			ID:    "judge@court.example.com",
		},
	}

	err := contract.UpdateLandStatus(ctx, "PLOT001", "invalid")
	assert.Error(t, err)
	assert.Contains(t, err.Error(), "invalid status")
}
