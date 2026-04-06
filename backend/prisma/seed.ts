import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  // Tạo user mẫu
  const hashedPassword = await bcrypt.hash('123456', 10);
  const user = await prisma.user.upsert({
    where: { email: 'demo@artlearn.com' },
    update: {},
    create: {
      email: 'demo@artlearn.com',
      password_hash: hashedPassword,
      full_name: 'Demo Artist',
      bio: 'Họa sĩ đam mê sáng tạo',
    },
  });

  // Tạo tutorial 1
  const tutorial1 = await prisma.tutorial.upsert({
    where: { slug: 've-chan-dung-co-ban' },
    update: {},
    create: {
      title: 'Vẽ chân dung cơ bản',
      slug: 've-chan-dung-co-ban',
      category: 'Vẽ',
      description: 'Hướng dẫn từng bước vẽ chân dung cho người mới bắt đầu',
      thumbnail_url: 'https://picsum.photos/id/1/400/200',
      difficulty_level: 'Dễ',
      created_by: user.id,
      steps: {
        create: [
          {
            step_order: 1,
            title: 'Vẽ phác thảo hình oval',
            content: 'Bắt đầu với một hình oval nhẹ nhàng làm khung khuôn mặt. Chú ý tỷ lệ chiều dài/rộng.',
            image_url: 'https://picsum.photos/id/2/400/300',
          },
          {
            step_order: 2,
            title: 'Đánh dấu vị trí mắt, mũi, miệng',
            content: 'Chia khuôn mặt thành 3 phần bằng nhau. Mắt nằm ở đường chia thứ nhất, mũi ở đường thứ hai, miệng ở giữa phần còn lại.',
            image_url: 'https://picsum.photos/id/3/400/300',
          },
          {
            step_order: 3,
            title: 'Vẽ chi tiết mắt',
            content: 'Vẽ hình hạnh nhân, thêm lông mi và đồng tử. Tạo độ sâu bằng bóng đổ.',
            image_url: 'https://picsum.photos/id/4/400/300',
          },
          {
            step_order: 4,
            title: 'Hoàn thiện mũi và miệng',
            content: 'Vẽ cánh mũi, lỗ mũi và môi. Chú ý ánh sáng để tạo khối.',
            image_url: 'https://picsum.photos/id/5/400/300',
          },
        ],
      },
      materials: {
        create: [
          { name: 'Bút chì', quantity: '2B, 4B, 6B', note: 'Nên dùng loại mềm' },
          { name: 'Giấy vẽ', quantity: 'A4', note: 'Giấy mỹ thuật 120gsm' },
          { name: 'Tẩy', quantity: '1 cục', note: 'Tẩy mềm' },
        ],
      },
    },
  });

  // Tutorial 2
  await prisma.tutorial.upsert({
    where: { slug: 'lam-thiep-handmade' },
    update: {},
    create: {
      title: 'Làm thiệp handmade đơn giản',
      slug: 'lam-thiep-handmade',
      category: 'Thủ công',
      description: 'Tự tay làm thiệp tặng người thân với các bước đơn giản',
      thumbnail_url: 'https://picsum.photos/id/6/400/200',
      difficulty_level: 'Dễ',
      created_by: user.id,
      steps: {
        create: [
          {
            step_order: 1,
            title: 'Chuẩn bị giấy và dụng cụ',
            content: 'Giấy bìa màu, kéo, keo dán, ruy băng, hạt cườm.',
            image_url: 'https://picsum.photos/id/7/400/300',
          },
          {
            step_order: 2,
            title: 'Gấp đôi tờ giấy',
            content: 'Tạo hình thiệp cơ bản, có thể cắt bo góc cho đẹp.',
            image_url: 'https://picsum.photos/id/8/400/300',
          },
          {
            step_order: 3,
            title: 'Trang trí mặt trước',
            content: 'Dán hoa, ruy băng, viết lời chúc bằng bút màu.',
            image_url: 'https://picsum.photos/id/9/400/300',
          },
        ],
      },
      materials: {
        create: [
          { name: 'Giấy bìa màu', quantity: '2 tờ' },
          { name: 'Kéo, keo dán', quantity: '1 bộ' },
          { name: 'Ruy băng, hạt cườm', quantity: 'Tùy ý' },
        ],
      },
    },
  });

  console.log('Seed completed!');
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());