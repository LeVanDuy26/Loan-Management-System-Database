# Database Design Documentation

## Tổng quan

Hệ thống cơ sở dữ liệu MySQL này được thiết kế để quản lý toàn bộ vòng đời của khoản vay, từ đơn xin vay ban đầu đến khi hoàn tất trả nợ hoặc thu hồi. Hệ thống hỗ trợ cho vay cá nhân với các tính năng đánh giá tín dụng, quy trình phê duyệt đa cấp, quản lý tài sản thế chấp, người bảo lãnh, và tính toán lãi suất linh hoạt.

## Kiến trúc Database

### Core Entities (Thực thể cốt lõi)

#### 1. customers
Bảng quản lý thông tin khách hàng.

**Mục đích**: Lưu trữ thông tin cơ bản và liên hệ của khách hàng.

**Các trường quan trọng**:
- `customer_id`: Primary key tự động tăng
- `customer_code`: Mã khách hàng duy nhất
- `id_number`: Số CMND/CCCD duy nhất
- `status`: Trạng thái khách hàng (active, inactive, blacklisted)

**Business Rules**:
- Mỗi khách hàng phải có customer_code và id_number duy nhất
- Khách hàng bị blacklisted không thể tạo đơn vay mới

#### 2. loan_applications
Bảng quản lý đơn xin vay.

**Mục đích**: Lưu trữ thông tin đơn xin vay của khách hàng.

**Các trường quan trọng**:
- `application_id`: Primary key
- `customer_id`: Foreign key đến customers
- `application_number`: Số đơn tự động tạo
- `loan_amount`: Số tiền vay yêu cầu
- `status`: Trạng thái đơn (pending, approved, rejected, cancelled)

**Business Rules**:
- application_number được tự động tạo bằng trigger
- Chỉ đơn approved mới có thể tạo contract
- loan_amount phải > 0

#### 3. loan_contracts
Bảng quản lý hợp đồng vay.

**Mục đích**: Lưu trữ thông tin hợp đồng vay sau khi đơn được phê duyệt.

**Các trường quan trọng**:
- `contract_id`: Primary key
- `application_id`: Foreign key đến loan_applications
- `contract_number`: Số hợp đồng tự động tạo
- `principal_amount`: Số tiền gốc
- `interest_rate`: Lãi suất (%)
- `term_months`: Kỳ hạn vay (tháng)
- `maturity_date`: Ngày đáo hạn (tự động tính)

**Business Rules**:
- maturity_date được tự động tính từ disbursement_date + term_months
- interest_rate phải trong khoảng 0-100%
- principal_amount phải > 0

#### 4. disbursements
Bảng quản lý giải ngân.

**Mục đích**: Theo dõi các giao dịch giải ngân cho hợp đồng vay.

**Các trường quan trọng**:
- `disbursement_id`: Primary key
- `contract_id`: Foreign key đến loan_contracts
- `amount`: Số tiền giải ngân
- `disbursement_method`: Phương thức giải ngân
- `status`: Trạng thái (pending, completed, failed, cancelled)

**Business Rules**:
- Tổng số tiền giải ngân không được vượt quá principal_amount
- disbursement_date không được là ngày tương lai
- Validation được thực hiện bằng trigger

#### 5. repayments
Bảng quản lý trả nợ.

**Mục đích**: Theo dõi các khoản thanh toán của khách hàng.

**Các trường quan trọng**:
- `repayment_id`: Primary key
- `contract_id`: Foreign key đến loan_contracts
- `scheduled_date`: Ngày hẹn trả
- `actual_payment_date`: Ngày thực tế trả
- `principal_amount`, `interest_amount`, `penalty_amount`: Các thành phần thanh toán
- `total_amount`: Tổng số tiền phải trả

**Business Rules**:
- scheduled_date không được trước disbursement_date của contract
- Tất cả các amount phải >= 0
- total_amount = principal_amount + interest_amount + penalty_amount

#### 6. collections
Bảng quản lý hoạt động thu hồi.

**Mục đích**: Theo dõi các hoạt động thu hồi nợ quá hạn.

**Các trường quan trọng**:
- `collection_id`: Primary key
- `contract_id`: Foreign key đến loan_contracts
- `collection_type`: Loại hoạt động (reminder, warning, legal_action, settlement)
- `amount_due`: Số tiền nợ
- `amount_collected`: Số tiền đã thu

**Business Rules**:
- amount_collected không được vượt quá amount_due
- Các amount phải >= 0

### Supporting Entities (Thực thể hỗ trợ)

#### 7. collaterals
Bảng quản lý tài sản thế chấp.

**Mục đích**: Lưu trữ thông tin tài sản đảm bảo cho khoản vay.

**Các trường quan trọng**:
- `collateral_id`: Primary key
- `contract_id`: Foreign key đến loan_contracts
- `collateral_type`: Loại tài sản (real_estate, vehicle, deposit, other)
- `estimated_value`: Giá trị ước tính
- `appraised_value`: Giá trị thẩm định

**Business Rules**:
- estimated_value và appraised_value phải > 0
- Một contract có thể có nhiều collaterals

#### 8. guarantors
Bảng quản lý người bảo lãnh.

**Mục đích**: Lưu trữ thông tin người bảo lãnh cho khoản vay.

**Các trường quan trọng**:
- `guarantor_id`: Primary key
- `contract_id`: Foreign key đến loan_contracts
- `guarantee_amount`: Số tiền bảo lãnh
- `relationship_with_customer`: Mối quan hệ với khách hàng

**Business Rules**:
- guarantee_amount phải > 0
- Một contract có thể có nhiều guarantors

#### 9. credit_scores
Bảng quản lý điểm tín dụng.

**Mục đích**: Lưu trữ kết quả đánh giá tín dụng của khách hàng.

**Các trường quan trọng**:
- `credit_score_id`: Primary key
- `customer_id`: Foreign key đến customers
- `application_id`: Foreign key đến loan_applications (nullable)
- `score`: Điểm tín dụng (0-1000)
- `rating`: Xếp hạng (excellent, good, fair, poor)
- `factors`: JSON chứa các yếu tố ảnh hưởng

**Business Rules**:
- score phải trong khoảng 0-1000
- rating phải khớp với score:
  - excellent: >= 750
  - good: 650-749
  - fair: 550-649
  - poor: < 550

#### 10. approval_workflows
Bảng quản lý quy trình phê duyệt.

**Mục đích**: Theo dõi quy trình phê duyệt đa cấp cho đơn vay.

**Các trường quan trọng**:
- `workflow_id`: Primary key
- `application_id`: Foreign key đến loan_applications
- `approver_level`: Cấp độ người phê duyệt
- `action`: Hành động (approve, reject, request_info)
- `status`: Trạng thái (pending, approved, rejected)

**Business Rules**:
- approver_level phải > 0
- Một application có thể có nhiều workflow records

#### 11. interest_rate_schedules
Bảng quản lý lịch lãi suất.

**Mục đích**: Quản lý lãi suất cố định và thả nổi cho hợp đồng.

**Các trường quan trọng**:
- `schedule_id`: Primary key
- `contract_id`: Foreign key đến loan_contracts
- `effective_date`: Ngày có hiệu lực
- `rate`: Lãi suất
- `rate_type`: Loại (fixed, floating)
- `base_rate`, `spread`: Dùng cho lãi suất thả nổi

**Business Rules**:
- Nếu rate_type = 'floating', base_rate phải không null
- effective_date không được trước disbursement_date
- Chỉ một rate active tại một thời điểm cho mỗi contract

#### 12. payment_schedules
Bảng quản lý lịch trả nợ.

**Mục đích**: Lưu trữ lịch trả nợ định kỳ cho hợp đồng.

**Các trường quan trọng**:
- `schedule_id`: Primary key
- `contract_id`: Foreign key đến loan_contracts
- `installment_number`: Số kỳ trả
- `due_date`: Ngày đến hạn
- `principal_due`, `interest_due`: Số tiền gốc và lãi đến hạn
- `paid_amount`: Số tiền đã trả
- `outstanding_amount`: Số tiền còn nợ (tự động tính)

**Business Rules**:
- outstanding_amount = total_due - paid_amount (tự động tính bằng trigger)
- total_due = principal_due + interest_due
- due_date không được trước disbursement_date
- Status tự động cập nhật dựa trên paid_amount và due_date

## Performance Considerations

### Indexes
- Tất cả foreign keys đều có indexes
- Composite indexes cho các query phổ biến:
  - `(customer_id, status)` cho loan_applications
  - `(contract_id, status)` cho disbursements, repayments
  - `(due_date, status)` cho payment_schedules để query overdue
  - `(customer_id, score_date DESC)` cho credit_scores để lấy điểm mới nhất

### Partitioning
- Có thể partition các bảng lớn (repayments, collections) theo date nếu cần
- Khuyến nghị partition theo disbursement_date hoặc created_at

### Query Optimization
- Sử dụng view `vw_loan_summary` cho reporting
- Tránh full table scan bằng cách sử dụng indexes phù hợp
- Sử dụng EXPLAIN để phân tích query plans

## Data Integrity

### Constraints
- Foreign key constraints với ON DELETE/UPDATE rules phù hợp
- Check constraints cho validation (amounts > 0, dates hợp lý)
- Unique constraints cho business keys
- NOT NULL constraints cho các trường bắt buộc

### Triggers
- Auto-generation của application_number, contract_number, disbursement_number
- Auto-calculation của maturity_date, outstanding_amount
- Validation triggers cho business rules
- Auto-update của contract status dựa trên payment schedules

## Security Considerations

### Sensitive Data
- `id_number`: Nên được mã hóa trong production
- `bank_account`: Nên được mã hóa trong production
- `transaction_reference`: Có thể chứa thông tin nhạy cảm

### Access Control
- Khuyến nghị sử dụng MySQL roles và privileges
- Tách biệt quyền đọc và ghi
- Audit logging cho các thao tác quan trọng

## Scalability

### Data Types
- Sử dụng BIGINT cho primary keys để hỗ trợ scale lớn
- DECIMAL(15, 2) cho tiền tệ để đảm bảo độ chính xác
- JSON cho flexible data (credit_score factors)

### Normalization
- Database được normalize đến 3NF
- Tránh redundancy nhưng vẫn đảm bảo performance

## Maintenance

### Backup Strategy
- Khuyến nghị backup hàng ngày cho production
- Point-in-time recovery cho các bảng quan trọng
- Test restore procedures định kỳ

### Monitoring
- Monitor slow queries
- Track table sizes và growth rates
- Monitor index usage và fragmentation

