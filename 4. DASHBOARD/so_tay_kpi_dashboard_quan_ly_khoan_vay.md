# SỔ TAY GIẢI THÍCH KPI VÀ CÁCH ĐỌC DASHBOARD QUẢN LÝ KHOẢN VAY

## 1. Mục đích tài liệu

Tài liệu này hỗ trợ ba mục tiêu:

1. Hiểu đúng bản chất từng KPI trong báo cáo Power BI.
2. Giải thích được công thức, logic nghiệp vụ và mức độ ảnh hưởng của KPI.
3. Biết cách đọc dashboard để rút ra insight có căn cứ, thay vì chỉ mô tả biểu đồ.

Phạm vi gồm:

- **Trang 1 — Tổng quan danh mục cho vay**
- **Trang 2 — Hồ sơ vay và phê duyệt tín dụng**
- **Trang 3 — Quá hạn, thu hồi và tài sản bảo đảm**

---

# 2. Nguyên tắc chung khi đọc KPI tín dụng

## 2.1. Phân biệt KPI dòng và KPI tồn

### KPI dòng — Flow KPI

Phản ánh giá trị phát sinh trong một khoảng thời gian:

- Giải ngân trong tháng.
- Tiền thu trong tháng.
- Hồ sơ nộp trong tháng.
- Hoạt động collection trong tháng.

Flow KPI luôn phải trả lời: **phát sinh trong khoảng thời gian nào?**

### KPI tồn — Stock KPI

Phản ánh trạng thái tại một thời điểm:

- Dư nợ gốc hiện tại.
- Số hợp đồng còn dư nợ.
- PAR 30+ hiện tại.
- DPD hiện tại.
- Giá trị tài sản bảo đảm đang hiệu lực.

Stock KPI luôn phải trả lời: **tại ngày báo cáo, trạng thái là bao nhiêu?**

Không nên so trực tiếp KPI flow với KPI stock nếu chưa làm rõ bối cảnh thời gian.

## 2.2. Phân biệt dư nợ gốc và nghĩa vụ hợp đồng còn lại

**Dư nợ gốc:**

```text
Dư nợ gốc
= Tổng giải ngân hoàn thành
- Tổng gốc đã thu
```

**Nghĩa vụ hợp đồng còn lại:**

```text
Gốc còn phải trả
+ Lãi còn phải trả theo lịch
```

Ví dụ:

- Dư nợ gốc: 80 triệu.
- Lãi còn lại theo lịch: 12 triệu.
- Nghĩa vụ hợp đồng còn lại: 92 triệu.

Hai KPI không được gọi chung là “dư nợ”.

## 2.3. Không kết luận từ một KPI đơn lẻ

Ví dụ:

- Giải ngân tăng chưa chắc tốt nếu PAR cũng tăng mạnh.
- Approval Rate cao chưa chắc tốt nếu điểm tín dụng giảm.
- Recovery Rate cao chưa chắc bền vững nếu chỉ đến từ vài khoản lớn.
- LTV thấp chưa chắc an toàn nếu DPD rất cao.

Insight tốt thường kết hợp:

```text
Quy mô + Chất lượng + Xu hướng
```

## 2.4. Khung suy luận chuẩn

1. **Quan sát:** KPI tăng, giảm hay đi ngang?
2. **So sánh:** So với kỳ trước, mục tiêu hoặc nhóm khác?
3. **Phân rã:** Thay đổi đến từ mục đích vay, rating hay trạng thái nào?
4. **Liên kết:** KPI có liên quan KPI nào ở trang khác?
5. **Kết luận:** Tác động kinh doanh và hành động cần thiết là gì?

---

# 3. TRANG 1 — TỔNG QUAN DANH MỤC CHO VAY

## 3.1. Mục tiêu của trang

Trang 1 phản ánh:

- Quy mô giải ngân.
- Dòng tiền thu về.
- Dư nợ hiện tại.
- Số lượng hợp đồng và khách hàng.
- Lãi suất bình quân.
- Cơ cấu và mức độ tập trung danh mục.

Trang phù hợp với ban điều hành, quản lý tín dụng và quản lý tài chính.

---

## KPI 1. Giải ngân trong kỳ

### DAX

```DAX
Disbursement In Period =
CALCULATE(
    [Completed Disbursement Amount],
    USERELATIONSHIP(
        'DimDate'[Date],
        'disbursements'[disbursement_date]
    )
)
```

### Công thức nghiệp vụ

```text
Tổng amount của disbursement
có status = "completed"
và ngày giải ngân nằm trong kỳ
```

### Ý nghĩa

Phản ánh lượng vốn thực tế đã cấp cho khách hàng trong kỳ.

### Logic kinh doanh

Chỉ tính `completed`; không tính `pending`, `failed`, `cancelled`.

### Ví dụ

Completed 8 tỷ, pending 1 tỷ, failed 0,5 tỷ. KPI đúng là **8 tỷ**.

### Mức độ ảnh hưởng

**Rất cao:** ảnh hưởng dư nợ, nhu cầu vốn, thu nhập lãi kỳ vọng và rủi ro tương lai.

### Cách đọc và suy luận

- Tăng đều: hoạt động cấp tín dụng mở rộng.
- Tăng đột biến: kiểm tra nguồn tăng trưởng.
- Giảm kéo dài: có thể do nhu cầu yếu hoặc chính sách siết.

Không kết luận “tăng là tốt” trước khi kiểm tra Credit Score, Approval Rate và PAR.

### Insight mẫu

> Giải ngân tăng 30%, chủ yếu từ nhóm vay kinh doanh; điểm tín dụng bình quân của nhóm này thấp hơn toàn danh mục 45 điểm. Tăng trưởng đang chuyển sang nhóm rủi ro cao hơn.

---

## KPI 2. Gốc thu trong kỳ

### DAX

```DAX
Principal Repaid In Period =
CALCULATE(
    [Principal Repaid Amount],
    USERELATIONSHIP(
        'DimDate'[Date],
        'repayments'[actual_payment_date]
    )
)
```

### Ý nghĩa

Phần vốn gốc đã thu hồi từ khách hàng.

### Logic kinh doanh

Gốc thu làm giảm dư nợ, tạo vốn quay vòng và giảm vốn bị khóa.

### Ví dụ

Khoản trả 6 triệu gồm 4,5 triệu gốc, 1,3 triệu lãi, 0,2 triệu phạt. KPI gốc thu là **4,5 triệu**.

### Mức độ ảnh hưởng

**Rất cao:** gốc thu thấp kéo dài làm dư nợ và nhu cầu vốn tăng.

### Insight mẫu

> Gốc thu chỉ bằng 55% giải ngân mới, làm dư nợ tăng nhanh và tạo áp lực nguồn vốn.

---

## KPI 3. Lãi thu trong kỳ

### DAX

```DAX
Interest Collected In Period =
CALCULATE(
    [Interest Collected Amount],
    USERELATIONSHIP(
        'DimDate'[Date],
        'repayments'[actual_payment_date]
    )
)
```

### Ý nghĩa

Phần tiền lãi thực tế đã thu bằng tiền.

### Logic kinh doanh

Đây là `cash interest collected`, không phải doanh thu lãi dồn tích hoặc lợi nhuận ròng.

### Ví dụ

Lãi phát sinh theo lịch 800 triệu, thực thu 650 triệu. KPI là **650 triệu**.

### Mức độ ảnh hưởng

**Cao:** ảnh hưởng dòng tiền và khả năng bù chi phí vốn.

### Insight mẫu

> Lãi thu tăng 18% trong khi dư nợ tăng 6%; cần kiểm tra lãi suất bình quân và chất lượng thanh toán để xác định nguyên nhân.

---

## KPI 4. Tiền phạt thu trong kỳ

### DAX

```DAX
Penalty Collected In Period =
CALCULATE(
    [Penalty Collected Amount],
    USERELATIONSHIP(
        'DimDate'[Date],
        'repayments'[actual_payment_date]
    )
)
```

### Ý nghĩa

Số tiền phạt đã thu do vi phạm nghĩa vụ thanh toán.

### Logic kinh doanh

Tiền phạt tăng có thể là tín hiệu nợ trễ tăng, không phải doanh thu lành mạnh.

### Ví dụ

Tiền phạt tăng từ 50 lên 120 triệu; cần kiểm tra DPD và số hợp đồng quá hạn.

### Mức độ ảnh hưởng

**Trung bình về quy mô nhưng cao về tín hiệu rủi ro.**

### Insight mẫu

> Tiền phạt tăng 140% cùng với số hợp đồng quá hạn tăng 60%; đây là dấu hiệu chất lượng thanh toán xấu đi.

---

## KPI 5. Tổng tiền thu trong kỳ

### DAX

```DAX
Cash Collected In Period =
[Principal Repaid In Period]
    + [Interest Collected In Period]
    + [Penalty Collected In Period]
```

### Ý nghĩa

Tổng dòng tiền thực thu từ khách hàng.

### Ví dụ

Gốc 5 tỷ, lãi 1 tỷ, phạt 0,1 tỷ → tổng thu **6,1 tỷ**.

### Mức độ ảnh hưởng

**Rất cao:** tác động thanh khoản và khả năng tái giải ngân.

### Insight mẫu

> Tổng tiền thu tăng 12%, nhưng phần tăng chủ yếu đến từ tiền phạt trong khi gốc thu giảm; cơ cấu dòng tiền đang kém lành mạnh.

---

## KPI 6. Dòng tiền cho vay thuần

### DAX

```DAX
Net Lending Cash Flow In Period =
[Cash Collected In Period]
    - [Disbursement In Period]
```

### Ý nghĩa

Dòng tiền ròng từ cấp và thu hồi khoản vay trong kỳ.

### Ví dụ

Thu 7 tỷ, giải ngân 10 tỷ → dòng tiền thuần **-3 tỷ**.

### Logic kinh doanh

Âm chưa chắc xấu nếu doanh nghiệp đang tăng trưởng; dương chưa chắc tốt nếu giải ngân đình trệ.

### Mức độ ảnh hưởng

**Cao đối với thanh khoản và chiến lược tăng trưởng.**

### Insight mẫu

> Dòng tiền thuần âm ba tháng liên tiếp nhưng PAR ổn định và giải ngân tăng đều; đây có thể là tăng trưởng chủ động.

---

## KPI 7. Dư nợ gốc hiện tại

### DAX

```DAX
Outstanding Principal =
SUMX(
    VALUES('loan_contracts'[contract_id]),
    VAR DisbursedAmount =
        CALCULATE([Completed Disbursement Amount])
    VAR PrincipalPaid =
        CALCULATE([Principal Repaid Amount])
    RETURN
        MAX(0, DisbursedAmount - PrincipalPaid)
)
```

### Ý nghĩa

Số vốn gốc còn đang được khách hàng sử dụng tại ngày báo cáo.

### Ví dụ

Giải ngân 100 triệu, đã thu gốc 35 triệu → dư nợ **65 triệu**.

### Logic kinh doanh

Là mẫu số của PAR, LTV và nhiều KPI rủi ro.

### Mức độ ảnh hưởng

**Rất cao.**

### Cách đọc

Dư nợ tăng cần phân tích do giải ngân mới hay gốc thu chậm, tăng ở nhóm nào và DPD nào.

### Insight mẫu

> Dư nợ tăng 15%, toàn bộ mức tăng tập trung ở mục đích vay kinh doanh và rating fair; rủi ro tập trung đang tăng.

---

## KPI 8. Nghĩa vụ hợp đồng còn lại

### DAX

```DAX
Remaining Contractual Obligation =
SUM('payment_schedules'[outstanding_amount])
```

### Ý nghĩa

Tổng số tiền còn phải trả theo lịch, gồm gốc và lãi.

### Ví dụ

Gốc còn 65 triệu, lãi còn 8 triệu → nghĩa vụ còn lại **73 triệu**.

### Mức độ ảnh hưởng

**Cao đối với dự báo dòng tiền.**

### Insight mẫu

> Nghĩa vụ còn lại cao hơn dư nợ gốc 14%, cho thấy thu nhập lãi tương lai còn đáng kể nhưng phải kiểm tra khả năng thu qua DPD.

---

## KPI 9. Số hợp đồng còn dư nợ

### DAX

```DAX
Contracts With Balance =
COUNTROWS(
    FILTER(
        VALUES('loan_contracts'[contract_id]),
        CALCULATE([Outstanding Principal]) > 0
    )
)
```

### Ý nghĩa

Số hợp đồng vẫn còn nghĩa vụ gốc.

### Ví dụ

Dư nợ 50 tỷ trên 500 hợp đồng → bình quân 100 triệu/hợp đồng.

### Mức độ ảnh hưởng

**Cao đối với quy mô vận hành.**

### Insight mẫu

> Dư nợ tăng 20% nhưng số hợp đồng chỉ tăng 5%; quy mô khoản vay bình quân và rủi ro tập trung tăng.

---

## KPI 10. Số khách hàng còn dư nợ

### DAX

```DAX
Borrowers With Balance =
COUNTROWS(
    FILTER(
        VALUES('customers'[customer_id]),
        CALCULATE([Outstanding Principal]) > 0
    )
)
```

### Ý nghĩa

Số khách hàng có ít nhất một khoản vay còn dư nợ.

### Ví dụ

600 hợp đồng trên 500 khách hàng → 1,2 hợp đồng/khách hàng.

### Mức độ ảnh hưởng

**Trung bình đến cao.**

### Insight mẫu

> Số hợp đồng tăng nhanh hơn số khách hàng; khách hàng hiện hữu đang vay thêm nhiều hơn, cần kiểm tra tập trung theo khách hàng.

---

## KPI 11. Giá trị giải ngân bình quân

### DAX

```DAX
Average Ticket Size =
DIVIDE(
    [Disbursement In Period],
    [Disbursed Contracts In Period]
)
```

### Ý nghĩa

Quy mô giải ngân trung bình trên mỗi hợp đồng.

### Ví dụ

20 tỷ trên 200 hợp đồng → **100 triệu/hợp đồng**.

### Mức độ ảnh hưởng

**Cao:** ticket lớn tăng doanh thu nhưng cũng tăng tổn thất nếu vỡ nợ.

### Insight mẫu

> Ticket size tăng 35% trong khi số hợp đồng không đổi; tăng trưởng đến từ khoản vay lớn hơn chứ không phải mở rộng tệp.

---

## KPI 12. Lãi suất bình quân gia quyền

### DAX

```DAX
Weighted Average Interest Rate =
DIVIDE(
    SUMX(
        FILTER(
            VALUES('loan_contracts'[contract_id]),
            CALCULATE([Outstanding Principal]) > 0
        ),
        VAR ContractBalance =
            CALCULATE([Outstanding Principal])
        VAR ContractRate =
            CALCULATE([Applied Interest Rate])
        RETURN
            ContractBalance * ContractRate
    ),
    [Outstanding Principal]
)
```

### Ý nghĩa

Mức lãi suất bình quân theo trọng số dư nợ.

### Ví dụ

100 triệu ở 10% và 900 triệu ở 15% → bình quân gia quyền **14,5%**, không phải 12,5%.

### Mức độ ảnh hưởng

**Cao đối với tiềm năng thu nhập và định giá rủi ro.**

### Insight mẫu

> Lãi suất bình quân tăng từ 12,1% lên 13,4% trong khi điểm tín dụng giảm; pricing đang tăng để bù rủi ro.

---

## KPI 13. Hợp đồng đáo hạn trong 90 ngày

### DAX

```DAX
Contracts Maturing In 90 Days =
COUNTROWS(
    FILTER(
        VALUES('loan_contracts'[contract_id]),
        VAR MaturityDate =
            CALCULATE(MAX('loan_contracts'[maturity_date]))
        VAR Balance =
            CALCULATE([Outstanding Principal])
        RETURN
            Balance > 0
                && MaturityDate >= TODAY()
                && MaturityDate <= TODAY() + 90
    )
)
```

### Ý nghĩa

Số hợp đồng còn dư nợ và sắp đáo hạn trong 90 ngày.

### Mức độ ảnh hưởng

**Cao đối với vận hành và thanh khoản.**

### Insight mẫu

> 30% dư nợ sẽ đáo hạn trong ba tháng, trong đó 40% thuộc DPD trên 30 ngày; áp lực thu hồi ngắn hạn cao.

---

## KPI 14. Tỷ lệ tiền thu trên giải ngân

### DAX

```DAX
Cash Collection To Disbursement Rate =
DIVIDE(
    [Cash Collected In Period],
    [Disbursement In Period]
)
```

### Ý nghĩa

So sánh dòng tiền thu với giải ngân trong cùng kỳ; không phải repayment rate.

### Ví dụ

Thu 8 tỷ, giải ngân 10 tỷ → **80%**.

### Insight mẫu

> Tỷ lệ giảm từ 95% xuống 60% do giải ngân tăng nhanh; cần kiểm tra PAR để phân biệt tăng trưởng chủ động với suy giảm thu nợ.

---

## 3.2. Cách đọc Trang 1

### Trình tự

1. **Quy mô:** giải ngân, dư nợ, hợp đồng, ticket size.
2. **Dòng tiền:** gốc, lãi, phạt, tổng thu, net cash flow.
3. **Cơ cấu:** mục đích vay, trạng thái, rating, thời hạn.
4. **Liên kết:** sang Trang 2 để kiểm tra chất lượng đầu vào; sang Trang 3 để kiểm tra PAR và DPD.

### Mẫu insight chuẩn

> Dư nợ tăng 18% do ticket size tăng 22% trong khi số hợp đồng chỉ tăng 3%. Tăng trưởng tập trung ở vay kinh doanh và lãi suất bình quân tăng 1,1 điểm phần trăm. Danh mục đang dịch chuyển sang khoản vay lớn và có pricing cao hơn; cần kiểm tra chất lượng tín dụng và PAR của nhóm này.

---

# 4. TRANG 2 — HỒ SƠ VAY VÀ PHÊ DUYỆT TÍN DỤNG

## 4.1. Mục tiêu

Phân tích chất lượng đầu vào và hiệu quả phê duyệt:

- Quy mô hồ sơ.
- Tỷ lệ phê duyệt và từ chối.
- Funnel hồ sơ.
- TAT.
- Điểm tín dụng.
- Mức cấp vốn.
- Hiệu quả workflow.

---

## KPI 1. Hồ sơ nộp trong kỳ

### DAX

```DAX
Applications Submitted =
CALCULATE(
    DISTINCTCOUNT('loan_applications'[application_id]),
    USERELATIONSHIP(
        'DimDate'[Date],
        'loan_applications'[submitted_date]
    )
)
```

### Ý nghĩa

Số nhu cầu vay mới phát sinh trong kỳ.

### Ví dụ

Tháng 4 có 500 hồ sơ, tháng 5 có 650 → tăng 30%.

### Mức độ ảnh hưởng

**Cao đối với tăng trưởng đầu vào.**

### Insight mẫu

> Hồ sơ tăng 30% nhưng Approval Rate giảm; tăng trưởng đầu vào có thể đến từ nhóm khách hàng kém phù hợp.

---

## KPI 2. Hồ sơ được duyệt trong kỳ

### DAX

```DAX
Applications Approved In Period =
CALCULATE(
    DISTINCTCOUNT('loan_applications'[application_id]),
    'loan_applications'[status] = "approved",
    USERELATIONSHIP(
        'DimDate'[Date],
        'loan_applications'[approved_date]
    )
)
```

### Ý nghĩa

Số quyết định phê duyệt được đưa ra trong kỳ.

### Ví dụ

Hồ sơ nộp 30/04 và duyệt 02/05 thuộc hồ sơ nộp tháng 4 nhưng quyết định duyệt tháng 5.

### Mức độ ảnh hưởng

**Cao đối với năng lực xử lý.**

---

## KPI 3. Tỷ lệ phê duyệt

### DAX

```DAX
Approval Rate =
DIVIDE(
    [Approved Submitted Cohort],
    [Decided Applications]
)
```

### Công thức

```text
Approved / (Approved + Rejected)
```

### Ví dụ

70 approved, 30 rejected, 20 pending → Approval Rate **70%**.

### Logic kinh doanh

Không đưa pending vào mẫu số vì chưa có quyết định.

### Mức độ ảnh hưởng

**Rất cao:** ảnh hưởng tăng trưởng, khẩu vị rủi ro và sales.

### Insight mẫu

> Approval Rate giảm từ 72% xuống 55% trong khi điểm tín dụng giảm 40 điểm; nguyên nhân nhiều khả năng là chất lượng đầu vào kém hơn.

---

## KPI 4. Tỷ lệ từ chối

### DAX

```DAX
Rejection Rate =
DIVIDE(
    [Rejected Submitted Cohort],
    [Decided Applications]
)
```

### Ý nghĩa

Tỷ lệ hồ sơ đã đánh giá nhưng không đạt điều kiện.

### Mức độ ảnh hưởng

**Cao.**

### Insight mẫu

> Tỷ lệ từ chối cao nhất ở nhóm vay tiêu dùng có điểm dưới 600 và kỳ hạn trên 24 tháng; đây là nhóm không phù hợp chính sách hiện tại.

---

## KPI 5. Tỷ lệ hồ sơ thành hợp đồng

### DAX

```DAX
Application To Contract Rate =
DIVIDE(
    [Contracted Applications],
    [Applications Submitted]
)
```

### Ý nghĩa

Tỷ lệ hồ sơ đầu vào cuối cùng tạo thành hợp đồng.

### Ví dụ

100 hồ sơ, 60 hợp đồng → **60%**.

### Mức độ ảnh hưởng

**Rất cao đối với hiệu quả funnel.**

### Insight mẫu

> Approval Rate 75% nhưng Application To Contract chỉ 50%; thất thoát lớn nằm sau phê duyệt.

---

## KPI 6. Tỷ lệ duyệt thành hợp đồng

### DAX

```DAX
Approved To Contract Rate =
DIVIDE(
    [Contracted Applications],
    [Approved Submitted Cohort]
)
```

### Ý nghĩa

Khả năng biến quyết định duyệt thành hợp đồng thực tế.

### Ví dụ

80 hồ sơ duyệt, 64 hợp đồng → **80%**.

### Mức độ ảnh hưởng

**Cao đối với hiệu quả sau phê duyệt.**

### Insight mẫu

> Tỷ lệ giảm ở nhóm Approved Amount Ratio dưới 70%; khách hàng có thể không chấp nhận mức cấp thấp.

---

## KPI 7. Thời gian phê duyệt trung bình

### DAX

```DAX
Average Approval TAT Days =
CALCULATE(
    AVERAGE('loan_applications'[Approval TAT Days]),
    'loan_applications'[status] = "approved",
    USERELATIONSHIP(
        'DimDate'[Date],
        'loan_applications'[submitted_date]
    )
)
```

### Ý nghĩa

Tốc độ xử lý hồ sơ từ nộp đến duyệt.

### Ví dụ

TAT 1, 2 và 6 ngày → trung bình 3 ngày.

### Mức độ ảnh hưởng

**Cao:** ảnh hưởng trải nghiệm, conversion và chi phí vận hành.

### Insight mẫu

> TAT tăng từ 1,8 lên 3,2 ngày cùng với Request Info Rate tăng ở level 2; nút thắt nằm ở chất lượng hồ sơ hoặc bước bổ sung thông tin.

---

## KPI 8. Thời gian phê duyệt trung vị

### DAX

```DAX
Median Approval TAT Days =
CALCULATE(
    MEDIAN('loan_applications'[Approval TAT Days]),
    'loan_applications'[status] = "approved",
    USERELATIONSHIP(
        'DimDate'[Date],
        'loan_applications'[submitted_date]
    )
)
```

### Ý nghĩa

Thời gian xử lý điển hình, ít bị ảnh hưởng bởi ngoại lệ.

### Ví dụ

TAT 1, 1, 2, 2, 20 → trung bình 5,2 nhưng trung vị 2 ngày.

### Insight mẫu

> Trung bình 5 ngày nhưng trung vị 2 ngày; một số hồ sơ ngoại lệ kéo dài đang làm xấu số trung bình.

---

## KPI 9. Điểm tín dụng bình quân

### DAX

```DAX
Average Latest Credit Score =
CALCULATE(
    AVERAGE('loan_applications'[Latest Credit Score]),
    USERELATIONSHIP(
        'DimDate'[Date],
        'loan_applications'[submitted_date]
    )
)
```

### Ý nghĩa

Chất lượng tín dụng bình quân của hồ sơ đầu vào hoặc nhóm đang lọc.

### Ví dụ

720, 680, 600 → bình quân 666,7.

### Mức độ ảnh hưởng

**Rất cao.**

### Insight mẫu

> Điểm tín dụng giảm 35 điểm nhưng Approval Rate giữ nguyên; chính sách phê duyệt có thể đã nới lỏng.

---

## KPI 10. Tổng số tiền yêu cầu vay

### DAX

```DAX
Requested Loan Amount =
CALCULATE(
    SUM('loan_applications'[loan_amount]),
    USERELATIONSHIP(
        'DimDate'[Date],
        'loan_applications'[submitted_date]
    )
)
```

### Ý nghĩa

Tổng nhu cầu vốn khách hàng yêu cầu.

### Insight mẫu

> Số hồ sơ tăng 5% nhưng tổng nhu cầu vốn tăng 25%; khách hàng đang yêu cầu khoản vay lớn hơn.

---

## KPI 11. Giá trị yêu cầu vay trung bình

### DAX

```DAX
Average Requested Loan Amount =
DIVIDE(
    [Requested Loan Amount],
    [Applications Submitted]
)
```

### Ý nghĩa

Quy mô khoản vay khách hàng mong muốn.

### Insight mẫu

> Yêu cầu bình quân 150 triệu nhưng giải ngân bình quân 105 triệu; mức cấp thực tế khoảng 70% nhu cầu.

---

## KPI 12. Tỷ lệ số tiền được cấp

### DAX

```DAX
Approved Amount Ratio =
DIVIDE(
    [Contract Principal For Submitted Cohort],
    [Requested Amount For Contracted Applications]
)
```

### Ý nghĩa

Mức độ tổ chức đáp ứng nhu cầu vốn sau thẩm định.

### Ví dụ

Yêu cầu 200 triệu, cấp 150 triệu → **75%**.

### Mức độ ảnh hưởng

**Cao đối với conversion và rủi ro.**

### Insight mẫu

> Approved Amount Ratio giảm ở rating fair và Approved To Contract cũng giảm; mức cấp thấp có thể làm khách hàng không ký.

---

## KPI 13. Số hành động workflow

### DAX

```DAX
Workflow Actions =
CALCULATE(
    COUNTROWS('approval_workflows'),
    USERELATIONSHIP(
        'DimDate'[Date],
        'approval_workflows'[action_date_only]
    )
)
```

### Ý nghĩa

Khối lượng hoạt động trong quy trình phê duyệt.

### Logic kinh doanh

Nhiều action/hồ sơ có thể phản ánh quy trình phức tạp hoặc hồ sơ thiếu thông tin.

### Mức độ ảnh hưởng

**Trung bình đến cao đối với chi phí vận hành.**

---

## KPI 14. Tỷ lệ yêu cầu bổ sung thông tin

### DAX

```DAX
Request Info Rate =
DIVIDE(
    [Request Info Actions],
    [Workflow Actions]
)
```

### Ý nghĩa

Mức độ hồ sơ phải bổ sung hoặc làm rõ.

### Ví dụ

100 actions, 25 request_info → **25%**.

### Mức độ ảnh hưởng

**Cao đối với TAT và trải nghiệm khách hàng.**

### Insight mẫu

> Request Info Rate tăng từ 15% lên 32%, tập trung ở level 2; đây là nguyên nhân chính làm TAT tăng.

---

## KPI 15. Số bước phê duyệt trung bình

### DAX

```DAX
Average Workflow Steps Per Application =
DIVIDE(
    [Workflow Actions],
    CALCULATE(
        DISTINCTCOUNT('approval_workflows'[application_id]),
        USERELATIONSHIP(
            'DimDate'[Date],
            'approval_workflows'[action_date_only]
        )
    )
)
```

### Ý nghĩa

Độ phức tạp trung bình của workflow trên mỗi hồ sơ.

### Ví dụ

300 actions/100 hồ sơ → 3 bước/hồ sơ.

### Insight mẫu

> Số bước tăng từ 2,4 lên 3,1 nhưng Approval Rate không cải thiện; quy trình phức tạp hơn mà chưa tạo thêm giá trị.

---

## 4.2. Cách đọc Trang 2

1. **Nhu cầu đầu vào:** hồ sơ, tổng tiền yêu cầu, giá trị yêu cầu bình quân.
2. **Chất lượng:** điểm tín dụng, rating, approval theo rating.
3. **Quyết định:** Approval Rate, Rejection Rate, Approved Amount Ratio.
4. **Funnel:** submitted → approved → contracted → disbursed.
5. **Vận hành:** TAT, median TAT, request info, workflow steps, approver.

### Mẫu insight chuẩn

> Hồ sơ tăng 20% nhưng điểm tín dụng giảm từ 700 xuống 655. Approval Rate giảm từ 72% xuống 58%, Request Info Rate tăng gấp đôi ở level 2 và TAT tăng từ 1,9 lên 3,1 ngày. Chất lượng hồ sơ đầu vào suy giảm đang làm tăng tải thẩm định và giảm conversion.

---

# 5. TRANG 3 — QUÁ HẠN, THU HỒI VÀ TÀI SẢN BẢO ĐẢM

## 5.1. Mục tiêu

Phân tích:

- DPD.
- Nghĩa vụ quá hạn.
- PAR 30+/90+.
- Hiệu quả collection.
- Backlog xử lý.
- Tài sản bảo đảm.
- LTV và dư nợ không bảo đảm.

---

## KPI 1. DPD

### DAX

```DAX
DPD =
VAR DueDate =
    'payment_schedules'[due_date]
VAR OutstandingAmount =
    'payment_schedules'[outstanding_amount]
RETURN
    IF(
        OutstandingAmount > 0
            && DueDate < TODAY(),
        DATEDIFF(DueDate, TODAY(), DAY),
        0
    )
```

### Ý nghĩa

Số ngày một nghĩa vụ thanh toán đã quá hạn.

### Ví dụ

Due date 01/06, ngày báo cáo 16/06, còn nợ → DPD 15.

### Mức độ ảnh hưởng

**Rất cao:** nền tảng của bucket, PAR và ưu tiên collection.

### Cách đọc

DPD càng cao, xác suất thu hồi thường giảm và chi phí xử lý tăng.

---

## KPI 2. DPD Bucket

### DAX

```DAX
DPD Bucket =
SWITCH(
    TRUE(),
    'payment_schedules'[DPD] = 0, "0. Current",
    'payment_schedules'[DPD] <= 30, "1. DPD 1-30",
    'payment_schedules'[DPD] <= 60, "2. DPD 31-60",
    'payment_schedules'[DPD] <= 90, "3. DPD 61-90",
    "4. DPD 90+"
)
```

### Ý nghĩa

Nhóm khoản quá hạn theo mức nghiêm trọng.

### Insight mẫu

> Dư nợ DPD 1–30 tăng mạnh nhưng DPD 90+ chưa tăng; đây là cảnh báo sớm và cần tác động collection nhanh.

---

## KPI 3. Nghĩa vụ quá hạn

### DAX

```DAX
Overdue Scheduled Amount =
CALCULATE(
    SUM('payment_schedules'[outstanding_amount]),
    FILTER(
        'payment_schedules',
        'payment_schedules'[outstanding_amount] > 0
            && 'payment_schedules'[due_date] < TODAY()
    )
)
```

### Ý nghĩa

Tổng gốc và lãi đã đến hạn nhưng chưa thanh toán hết.

### Ví dụ

Hợp đồng dư nợ gốc 80 triệu nhưng kỳ quá hạn 5 triệu → nghĩa vụ quá hạn 5 triệu.

### Mức độ ảnh hưởng

**Rất cao đối với collection ngắn hạn.**

### Insight mẫu

> Nghĩa vụ quá hạn tăng 40% nhưng PAR 30+ chỉ tăng nhẹ; phần lớn khoản có thể nằm ở DPD 1–30.

---

## KPI 4. Số kỳ trả nợ quá hạn

### DAX

```DAX
Overdue Installments =
CALCULATE(
    DISTINCTCOUNT('payment_schedules'[schedule_id]),
    FILTER(
        'payment_schedules',
        'payment_schedules'[outstanding_amount] > 0
            && 'payment_schedules'[due_date] < TODAY()
    )
)
```

### Ý nghĩa

Số kỳ thanh toán đang quá hạn.

### Insight mẫu

> Số kỳ quá hạn tăng 60% nhưng số hợp đồng chỉ tăng 10%; cùng một số hợp đồng đang tích lũy nhiều kỳ nợ hơn.

---

## KPI 5. Số hợp đồng quá hạn

### DAX

```DAX
Overdue Contracts =
CALCULATE(
    DISTINCTCOUNT('payment_schedules'[contract_id]),
    FILTER(
        'payment_schedules',
        'payment_schedules'[outstanding_amount] > 0
            && 'payment_schedules'[due_date] < TODAY()
    )
)
```

### Ý nghĩa

Số hợp đồng có ít nhất một kỳ quá hạn.

### Mức độ ảnh hưởng

**Rất cao.**

### Insight mẫu

> Số hợp đồng quá hạn giảm nhưng giá trị quá hạn tăng; ít khách hàng hơn nhưng quy mô nợ trên mỗi hợp đồng lớn hơn.

---

## KPI 6. Tỷ lệ hợp đồng quá hạn

### DAX

```DAX
Overdue Contract Rate =
DIVIDE(
    [Overdue Contracts],
    [Contracts With Balance]
)
```

### Ý nghĩa

Tỷ lệ hợp đồng còn dư nợ đang có vấn đề thanh toán.

### Ví dụ

12 hợp đồng quá hạn trên 100 hợp đồng còn dư nợ → 12%.

### Insight mẫu

> Tỷ lệ hợp đồng quá hạn tăng nhưng PAR 30+ chưa tăng tương ứng; nhiều khoản có thể mới quá hạn ngắn ngày.

---

## KPI 7. PAR 30+

### DAX

```DAX
PAR 30 Balance =
CALCULATE(
    [Outstanding Principal],
    FILTER(
        'loan_contracts',
        'loan_contracts'[Contract Max DPD] >= 30
    )
)

PAR 30 Rate =
DIVIDE(
    [PAR 30 Balance],
    [Outstanding Principal]
)
```

### Công thức

```text
Dư nợ gốc hợp đồng có DPD >= 30
/ Tổng dư nợ gốc
```

### Ví dụ

8 tỷ trên tổng dư nợ 100 tỷ → PAR 30+ = 8%.

### Logic kinh doanh

Toàn bộ dư nợ còn lại của hợp đồng DPD ≥ 30 được đưa vào tử số.

### Mức độ ảnh hưởng

**Rất cao.**

### Insight mẫu

> PAR 30+ tăng từ 5% lên 8% do ba hợp đồng lớn chuyển sang DPD 31–60; rủi ro tăng do tập trung.

---

## KPI 8. PAR 90+

### DAX

```DAX
PAR 90 Balance =
CALCULATE(
    [Outstanding Principal],
    FILTER(
        'loan_contracts',
        'loan_contracts'[Contract Max DPD] >= 90
    )
)

PAR 90 Rate =
DIVIDE(
    [PAR 90 Balance],
    [Outstanding Principal]
)
```

### Ý nghĩa

Tỷ trọng dư nợ thuộc khoản quá hạn nghiêm trọng.

### Ví dụ

3 tỷ trên 100 tỷ → PAR 90+ = 3%.

### Mức độ ảnh hưởng

**Rất cao:** liên quan xác suất vỡ nợ, dự phòng và xử lý pháp lý.

### Insight mẫu

> PAR 30+ ổn định nhưng PAR 90+ tăng; các khoản đã quá hạn không được chữa lành và tiếp tục xấu đi.

---

## KPI 9. Hoạt động collection trong kỳ

### DAX

```DAX
Collection Activities In Period =
CALCULATE(
    COUNTROWS('collections'),
    USERELATIONSHIP(
        'DimDate'[Date],
        'collections'[collection_date]
    )
)
```

### Ý nghĩa

Khối lượng hoạt động thu hồi đã ghi nhận.

### Insight mẫu

> Activity tăng 50% nhưng số tiền thu chỉ tăng 10%; hiệu quả trên mỗi hoạt động giảm.

---

## KPI 10. Số tiền collection phải thu

### DAX

```DAX
Collection Due In Period =
CALCULATE(
    SUM('collections'[amount_due]),
    USERELATIONSHIP(
        'DimDate'[Date],
        'collections'[collection_date]
    )
)
```

### Ý nghĩa

Tổng amount_due được ghi nhận trong các activity.

### Cảnh báo

Một hợp đồng có nhiều activity có thể lặp amount_due, nên không coi đây là tổng nợ danh mục.

---

## KPI 11. Số tiền thu qua collection

### DAX

```DAX
Collection Collected In Period =
CALCULATE(
    SUM('collections'[amount_collected]),
    USERELATIONSHIP(
        'DimDate'[Date],
        'collections'[collection_date]
    )
)
```

### Ý nghĩa

Số tiền được ghi nhận đã thu qua hoạt động collection.

### Insight mẫu

> Tiền thu tăng nhưng chủ yếu đến từ settlement; reminder và warning có hiệu quả thấp, cho thấy thu hồi đang diễn ra muộn.

---

## KPI 12. Tỷ lệ thu hồi trên activity

### DAX

```DAX
Collection Activity Recovery Rate =
DIVIDE(
    [Collection Collected In Period],
    [Collection Due In Period]
)
```

### Ví dụ

Due 1 tỷ, collected 300 triệu → 30%.

### Cảnh báo

Không coi là recovery rate chuẩn toàn danh mục nếu amount_due lặp giữa các activity.

### Mức độ ảnh hưởng

**Cao về vận hành.**

### Insight mẫu

> Recovery Rate giảm từ 35% xuống 22% trong khi activity tăng; cần nhiều hành động hơn nhưng thu được ít tiền hơn.

---

## KPI 13. Hợp đồng collection đang mở

### DAX

```DAX
Open Collection Contracts =
CALCULATE(
    DISTINCTCOUNT('collections'[contract_id]),
    'collections'[status] = "open"
)
```

### Ý nghĩa

Số hợp đồng có collection chưa được giải quyết.

### Mức độ ảnh hưởng

**Cao đối với backlog.**

### Insight mẫu

> Open cases tăng ba tháng liên tiếp; tốc độ đóng case thấp hơn tốc độ phát sinh.

---

## KPI 14. Hoạt động collection quá ngày

### DAX

```DAX
Overdue Collection Actions =
CALCULATE(
    COUNTROWS('collections'),
    FILTER(
        'collections',
        'collections'[status] = "open"
            && NOT ISBLANK('collections'[next_action_date])
            && 'collections'[next_action_date] < TODAY()
    )
)
```

### Ý nghĩa

Số activity đang mở nhưng đã quá ngày hành động tiếp theo.

### Mức độ ảnh hưởng

**Rất cao đối với kiểm soát vận hành.**

### Insight mẫu

> 28% action mở đã quá ngày và tập trung ở hai nhân viên; rủi ro đến cả từ backlog vận hành.

---

## KPI 15. Giá trị tài sản bảo đảm đang hiệu lực

### DAX

```DAX
Active Collateral Value =
SUMX(
    FILTER(
        'collaterals',
        'collaterals'[status] = "active"
    ),
    COALESCE(
        'collaterals'[appraised_value],
        'collaterals'[estimated_value]
    )
)
```

### Ý nghĩa

Tổng giá trị tài sản bảo đảm còn hiệu lực.

### Logic

Ưu tiên appraised value; nếu thiếu mới dùng estimated value.

### Cảnh báo

Giá trị tài sản không phải số tiền chắc chắn thu hồi vì còn haircut, chi phí và thời gian thanh lý.

---

## KPI 16. Portfolio LTV

### DAX

```DAX
Portfolio LTV =
DIVIDE(
    [Outstanding Principal],
    [Active Collateral Value]
)
```

### Ý nghĩa

Mức dư nợ trên giá trị tài sản bảo đảm.

### Ví dụ

Dư nợ 80 triệu, tài sản 100 triệu → LTV 80%.

### Mức độ ảnh hưởng

**Rất cao.**

### Insight mẫu

> Nhóm DPD 90+ có LTV 110%; dư nợ vượt giá trị tài sản, khả năng thu đủ gốc qua thanh lý thấp.

---

## KPI 17. Collateral Coverage

### DAX

```DAX
Collateral Coverage =
DIVIDE(
    [Active Collateral Value],
    [Outstanding Principal]
)
```

### Ý nghĩa

Tài sản bằng bao nhiêu lần dư nợ.

### Ví dụ

Tài sản 120 triệu, dư nợ 80 triệu → Coverage 150%.

### Mức độ ảnh hưởng

**Rất cao.**

---

## KPI 18. Dư nợ không có tài sản bảo đảm

### DAX

```DAX
Unsecured Outstanding =
SUMX(
    FILTER(
        VALUES('loan_contracts'[contract_id]),
        CALCULATE(
            COUNTROWS('collaterals'),
            'collaterals'[status] = "active"
        ) = 0
    ),
    CALCULATE([Outstanding Principal])
)
```

### Ý nghĩa

Phần dư nợ không có tài sản bảo đảm đang hiệu lực.

### Mức độ ảnh hưởng

**Rất cao.**

### Insight mẫu

> 35% dư nợ là không bảo đảm nhưng chiếm 60% PAR 30+; rủi ro tập trung ở khoản vay tín chấp.

---

## KPI 19. Tỷ lệ dư nợ không bảo đảm

### DAX

```DAX
Unsecured Outstanding Rate =
DIVIDE(
    [Unsecured Outstanding],
    [Outstanding Principal]
)
```

### Ý nghĩa

Tỷ trọng danh mục không có tài sản bảo đảm.

### Mức độ ảnh hưởng

**Rất cao đối với khẩu vị rủi ro.**

---

## KPI 20. Giá trị bảo lãnh đang hiệu lực

### DAX

```DAX
Active Guarantee Amount =
CALCULATE(
    SUM('guarantors'[guarantee_amount]),
    'guarantors'[status] = "active"
)
```

### Ý nghĩa

Giá trị nghĩa vụ bảo lãnh còn hiệu lực.

### Cảnh báo

Không coi tương đương tiền mặt hoặc tài sản có thanh khoản cao.

---

## 5.2. Cách đọc Trang 3

1. **Quá hạn hiện tại:** amount quá hạn, hợp đồng quá hạn, DPD bucket.
2. **Mức nghiêm trọng:** PAR 30+, PAR 60+, PAR 90+.
3. **Collection:** activity, amount collected, recovery, open cases, overdue actions.
4. **Khả năng giảm tổn thất:** collateral, LTV, coverage, unsecured balance.
5. **Ưu tiên:** DPD cao + dư nợ lớn + LTV cao + next action quá hạn.

### Mẫu insight chuẩn

> PAR 30+ tăng từ 6% lên 9% nhưng số hợp đồng quá hạn chỉ tăng 4%. Ba hợp đồng lớn chuyển sang DPD 31–60 chiếm phần lớn mức tăng; hai hợp đồng có LTV trên 100%. Rủi ro tập trung cao và cần ưu tiên collection.

---

# 6. LIÊN KẾT BA TRANG ĐỂ RÚT INSIGHT SÂU

## Kịch bản 1 — Giải ngân tăng nhưng chất lượng giảm

**Trang 1:** giải ngân, dư nợ và ticket size tăng.  
**Trang 2:** điểm tín dụng giảm nhưng Approval Rate không giảm.  
**Trang 3:** DPD 1–30 và PAR bắt đầu tăng.

**Insight:**

> Chính sách tăng trưởng có thể đang nới lỏng và cấp khoản vay lớn hơn cho nhóm chất lượng thấp hơn. Cần xem lại hạn mức và điều kiện cho rating fair.

## Kịch bản 2 — Approval Rate giảm nhưng danh mục tốt hơn

**Trang 2:** Approval Rate giảm, điểm của hồ sơ được duyệt tăng.  
**Trang 3:** PAR 30+ và DPD 90+ giảm.

**Insight:**

> Việc giảm Approval Rate có thể là kết quả của chính sách chọn lọc tốt hơn; chất lượng danh mục cải thiện cho thấy đánh đổi tăng trưởng–rủi ro đang hiệu quả.

## Kịch bản 3 — TAT tăng và conversion giảm

**Trang 2:** TAT, Request Info tăng; Approved To Contract giảm.  
**Trang 1:** giải ngân giảm.

**Insight:**

> Nút thắt workflow đang ảnh hưởng trực tiếp tăng trưởng. Cần cải thiện hồ sơ đầu vào hoặc giảm vòng request_info.

## Kịch bản 4 — Collection nhiều nhưng PAR vẫn tăng

**Trang 3:** activity tăng, recovery giảm, PAR và overdue actions tăng.

**Insight:**

> Collection đang tăng khối lượng nhưng giảm hiệu suất. Cần ưu tiên theo dư nợ, DPD và LTV thay vì phân bổ đồng đều.

---

# 7. KHUNG VIẾT INSIGHT CHUẨN

Một insight tốt có bốn phần:

```text
Biến động + Nguyên nhân + Tác động + Hành động
```

Mẫu câu:

> KPI A tăng/giảm so với kỳ trước. Thay đổi chủ yếu đến từ nhóm B. Điều này làm tăng/giảm rủi ro hoặc hiệu quả C. Do đó cần hành động D.

Ví dụ:

> PAR 30+ tăng từ 5% lên 8%, chủ yếu do nhóm vay kinh doanh có ticket trên 200 triệu. Nhóm này có LTV trên 90% và Recovery Rate thấp. Cần ưu tiên collection sớm và xem xét hạn mức phê duyệt.

---

# 8. LỖI PHỔ BIẾN KHI GIẢI THÍCH KPI

## 8.1. Chỉ mô tả, không phân tích

Yếu:

> Giải ngân tăng 20%.

Tốt:

> Giải ngân tăng 20%, chủ yếu do ticket size tăng, không phải số hợp đồng; mức độ tập trung trên mỗi khoản vay tăng.

## 8.2. Kết luận nhân quả khi chỉ có tương quan

Không nên nói:

> Điểm tín dụng thấp làm PAR tăng.

Nên nói:

> Nhóm điểm thấp có PAR cao hơn; mối liên hệ cần tiếp tục kiểm chứng theo thời gian và các yếu tố khác.

## 8.3. So sánh KPI khác grain

- Activity collection không tương đương hợp đồng.
- Nghĩa vụ quá hạn không tương đương toàn bộ dư nợ.
- Application không tương đương contract.

## 8.4. Bỏ qua thời gian

- Không dùng slicer tháng để khẳng định PAR lịch sử nếu chưa có snapshot.
- Không so stock KPI hiện tại trực tiếp với flow KPI một tháng mà không giải thích.

## 8.5. Coi cao/thấp là tốt/xấu tuyệt đối

- Approval Rate cao có thể là nới lỏng quá mức.
- Net Cash Flow âm có thể là tăng trưởng chủ động.
- Tiền phạt tăng có thể là chất lượng xấu đi.

---

# 9. CÁCH TRÌNH BÀY KHI BẢO VỆ KHÓA LUẬN

## Mở đầu Trang 1

> Trang này phản ánh quy mô, dòng tiền và cấu trúc danh mục. Các KPI giải ngân, dư nợ, tiền thu và lãi suất bình quân được dùng để đánh giá tăng trưởng và vận hành vốn.

## Mở đầu Trang 2

> Trang này phân tích chất lượng đầu vào và hiệu quả phê duyệt, từ khi hồ sơ được nộp đến khi hình thành hợp đồng.

## Mở đầu Trang 3

> Trang này tập trung rủi ro sau giải ngân, gồm quá hạn, PAR, thu hồi và mức độ bao phủ tài sản bảo đảm.

## Trình tự thuyết trình

1. Mục tiêu trang.
2. KPI chính.
3. Xu hướng nổi bật.
4. Phân rã nguyên nhân.
5. Insight.
6. Hành động.
7. Giới hạn dữ liệu.

---

# 10. GIỚI HẠN DỮ LIỆU

## 10.1. Chưa có snapshot lịch sử

Chưa tái dựng chính xác:

- PAR cuối từng tháng.
- Roll rate.
- Vintage.
- Cure rate lịch sử.

## 10.2. Chưa có đầy đủ dữ liệu lợi nhuận

Thiếu:

- Cost of fund.
- Operating cost.
- Provision.
- Write-off amount.
- Fee income đầy đủ.

Chưa tính được NIM, risk-adjusted return hoặc lợi nhuận ròng.

## 10.3. Collection có grain activity

Một hợp đồng có thể có nhiều activity; cần thận trọng khi cộng amount_due.

## 10.4. Giá trị tài sản chưa áp dụng haircut

LTV chưa phản ánh chi phí thanh lý, biến động giá và rủi ro pháp lý.

---

# 11. CHECKLIST ĐỌC DASHBOARD

## Trang 1

- Giải ngân tăng hay giảm?
- Dư nợ tăng do số hợp đồng hay ticket size?
- Tiền thu có theo kịp giải ngân?
- Tiền phạt có tăng bất thường?
- Danh mục tập trung ở đâu?
- Lãi suất bình quân đổi vì lý do gì?

## Trang 2

- Hồ sơ đầu vào tăng hay giảm?
- Chất lượng tín dụng thay đổi thế nào?
- Approval Rate đổi do chính sách hay chất lượng?
- Funnel mất nhiều nhất ở bước nào?
- TAT và Request Info có tạo nút thắt?
- Mức tiền được cấp có ảnh hưởng conversion?

## Trang 3

- DPD tăng ở bucket nào?
- PAR tăng do nhiều hợp đồng hay khoản lớn?
- Collection tăng hiệu quả hay chỉ tăng activity?
- Có backlog next action?
- Khoản rủi ro cao có tài sản đủ bao phủ?
- Dư nợ không bảo đảm chiếm bao nhiêu PAR?

---

# 12. KẾT LUẬN

Ba trang cần được đọc theo chuỗi:

```text
Trang 2 — Chất lượng đầu vào và quyết định
        ↓
Trang 1 — Quy mô giải ngân, dòng tiền và danh mục
        ↓
Trang 3 — Chất lượng sau giải ngân và khả năng thu hồi
```

Dashboard tốt không chỉ trả lời “đang có bao nhiêu”, mà còn phải trả lời:

- Vì sao con số thay đổi?
- Thay đổi tốt hay xấu trong bối cảnh nào?
- Rủi ro tập trung ở đâu?
- Cần hành động gì?

Khi giải thích KPI, phải gắn công thức kỹ thuật với ý nghĩa nghiệp vụ. Khi rút insight, phải kết hợp quy mô, chất lượng, xu hướng và nguyên nhân.
