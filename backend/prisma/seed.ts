import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
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

  // Tutorial 1: Vẽ chân dung
  await prisma.tutorial.upsert({
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
            title: 'Phác thảo hình dáng khuôn mặt',
            content: 'Vẽ một hình oval nhẹ nhàng. Chia khuôn mặt thành 3 phần bằng nhau.',
            image_url: 'https://picsum.photos/id/2/400/300',
          },
          {
            step_order: 2,
            title: 'Đánh dấu vị trí mắt, mũi, miệng',
            content: 'Kẻ các đường ngang để định vị. Mắt nằm ở đường thứ nhất, mũi ở đường thứ hai, miệng ở giữa phần còn lại.',
            image_url: 'https://picsum.photos/id/3/400/300',
          },
          {
            step_order: 3,
            title: 'Vẽ mắt',
            content: 'Vẽ hình hạnh nhân, thêm lông mi và đồng tử. Tạo độ sâu bằng bóng đổ.',
            image_url: 'https://picsum.photos/id/4/400/300',
          },
          {
            step_order: 4,
            title: 'Vẽ mũi và miệng',
            content: 'Vẽ cánh mũi, lỗ mũi. Môi trên mỏng hơn môi dưới.',
            image_url: 'https://picsum.photos/id/5/400/300',
          },
          {
            step_order: 5,
            title: 'Hoàn thiện tóc và cổ',
            content: 'Thêm tóc theo hướng, vẽ cổ và vai.',
            image_url: 'https://picsum.photos/id/6/400/300',
          },
        ],
      },
      materials: {
        create: [
          { name: 'Bút chì', quantity: '2B, 4B, 6B', note: 'Nên dùng loại mềm' },
          { name: 'Giấy vẽ', quantity: 'A4', note: 'Giấy mỹ thuật 120gsm' },
          { name: 'Tẩy', quantity: '1 cục', note: 'Tẩy mềm' },
          { name: 'Que chà', quantity: '1 cây', note: 'Để tạo bóng mịn' },
        ],
      },
    },
  });

  // Tutorial 2: Làm thiệp handmade
  await prisma.tutorial.upsert({
    where: { slug: 'lam-thiep-handmade' },
    update: {},
    create: {
      title: 'Làm thiệp handmade đơn giản',
      slug: 'lam-thiep-handmade',
      category: 'Thủ công',
      description: 'Tự tay làm thiệp tặng người thân với các bước đơn giản',
      thumbnail_url: 'https://picsum.photos/id/7/400/200',
      difficulty_level: 'Dễ',
      created_by: user.id,
      steps: {
        create: [
          {
            step_order: 1,
            title: 'Chuẩn bị giấy và dụng cụ',
            content: 'Giấy bìa màu, kéo, keo dán, ruy băng, hạt cườm.',
            image_url: 'https://picsum.photos/id/8/400/300',
          },
          {
            step_order: 2,
            title: 'Gấp đôi tờ giấy',
            content: 'Tạo hình thiệp cơ bản, có thể cắt bo góc cho đẹp.',
            image_url: 'https://picsum.photos/id/9/400/300',
          },
          {
            step_order: 3,
            title: 'Trang trí mặt trước',
            content: 'Dán hoa, ruy băng, viết lời chúc bằng bút màu.',
            image_url: 'https://picsum.photos/id/10/400/300',
          },
          {
            step_order: 4,
            title: 'Trang trí bên trong',
            content: 'Có thể dán thêm ảnh hoặc viết tay.',
            image_url: 'https://picsum.photos/id/11/400/300',
          },
        ],
      },
      materials: {
        create: [
          { name: 'Giấy bìa màu', quantity: '2 tờ' },
          { name: 'Kéo, keo dán', quantity: '1 bộ' },
          { name: 'Ruy băng, hạt cườm', quantity: 'Tùy ý' },
          { name: 'Bút màu', quantity: '1 bộ' },
        ],
      },
    },
  });

  console.log('Seed completed!');
}

main()
  .catch(e => console.error(e))
  .finally(async () => await prisma.$disconnect());