alias Autoslot.Repo
alias Autoslot.Services
alias Autoslot.Services.Service

services = [
  %{
    name: "Компьютерная диагностика",
    description:
      "Проверка электронных систем автомобиля, чтение ошибок и первичная оценка состояния.",
    duration_minutes: 30,
    price: 1500
  },
  %{
    name: "Замена масла",
    description: "Замена моторного масла и масляного фильтра с базовой проверкой автомобиля.",
    duration_minutes: 60,
    price: 2500
  },
  %{
    name: "Шиномонтаж",
    description: "Снятие, установка и балансировка колес.",
    duration_minutes: 60,
    price: 3000
  },
  %{
    name: "Ремонт тормозной системы",
    description: "Диагностика и ремонт элементов тормозной системы автомобиля.",
    duration_minutes: 90,
    price: 5000
  },
  %{
    name: "Диагностика подвески",
    description: "Проверка элементов подвески, рулевого управления и ходовой части.",
    duration_minutes: 45,
    price: 2000
  }
]

Enum.each(services, fn attrs ->
  case Repo.get_by(Service, name: attrs.name) do
    nil ->
      Services.create_service(attrs)

    _service ->
      :ok
  end
end)
