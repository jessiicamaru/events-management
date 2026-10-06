# Quy trình làm việc (workflow)

> Ghi chú quy trình của tác giả, giữ nguyên bản. Trước đây nằm cuối `README.md`, chuyển
> vào đây để README chỉ còn phần cài đặt và giới thiệu.

## Git

- git fetch: kéo graph tree và commit của toàn bộ nhánh đang có trên remote

- git pull: kéo code ở nhánh đang đứng về

- git checkout -b <ten nhanh>: tạo nhánh mới

- git checkout <ten nhanh>: chuyen qua nhánh đó

## Flow

- Đứng từ develop sử dụng [git checkout -b <ten nhanh>] để qua nhánh mới

- Đứng ở nhánh mới, kiểm tra file backlog ở trong thư mục /docs/feature-roadmap.md

- Chọn 1 task trong ý project-plan, sau đó rồi code.

- Code done khi: có unit test, đã tự test tay và UI chạy được, server chạy được, và có chạy E2E test

- Sau khi done code, push code lên remote. Chạy /compact để AI compact lại code và quản lý tiến trình

- Tạo Pull request trên github -> nếu không có conflict thì fix, nếu có conflict thì fix hoặc báo lên nếu k thể fix

- Sau khi merge, về lại IDE, gõ git checkout main để về nhánh main, gõ git pull để kéo code vừa merge về

## Lưu ý

- Update walkthrough sau mỗi lần làm xong 1 task

- Mỗi nhánh chỉ làm 1 task
